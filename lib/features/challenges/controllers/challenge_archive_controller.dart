import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/common/widgets/exam/premium_bottom_sheet.dart';
import 'package:matricmate/data/database/database_service.dart';
import 'package:matricmate/data/repositories/challenge/challenge_repository.dart';
import 'package:matricmate/features/challenges/models/challenge_attempt_model.dart';
import 'package:matricmate/features/challenges/models/challenge_model.dart';
import 'package:matricmate/features/challenges/models/challenge_question_model.dart';
import 'package:matricmate/features/challenges/controllers/challenge_home_controller.dart';
import 'package:matricmate/features/challenges/screens/challenge_review_screen.dart';
import 'package:matricmate/features/exam/controllers/subjects_controller.dart';
import 'package:matricmate/features/exam/models/subject_model.dart';
import 'package:matricmate/features/personalization/controllers/user_controller.dart';
import 'package:matricmate/utils/exceptions/exception_handler.dart';
import 'package:matricmate/utils/helpers/toast_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChallengeArchiveController extends GetxController {
  ChallengeArchiveController({this.subjectId, this.subjectTitle});

  static ChallengeArchiveController get instance => Get.find();

  final int? subjectId;
  final String? subjectTitle;

  late final RxnInt selectedSubjectId = RxnInt(subjectId);

  final _repo = ChallengeRepository();
  final _db = DatabaseService.instance;
  final _sb = Supabase.instance.client;

  final isLoading = false.obs;
  final isManualRefreshing = false.obs;
  final challenges = <LeaderboardChallengeModel>[].obs;
  final downloadedIds = <String>{}.obs;
  final isDownloading = <String, bool>{}.obs;
  final isOpeningReview = <String, bool>{}.obs;
  final attemptedIds = <String>{}.obs;
  final isOffline = false.obs;

  RealtimeChannel? _realtimeChannel;

  bool get isPremium => UserController.instance.user.value.isActive;
  String get userStream => UserController.instance.user.value.stream.toLowerCase().trim();

  List<SubjectModel> get studentSubjects {
    final streamTag = userStream;
    final isNatural = streamTag == 'natural';
    if (Get.isRegistered<SubjectsController>()) {
      final list = SubjectsController.instance.subjects;
      if (list.isEmpty) return [];
      if (streamTag.isEmpty) return list;
      return list.where((s) {
        return s.isCommon || (isNatural ? s.isNatural : !s.isNatural);
      }).toList();
    }
    return [];
  }

  String get selectedSubjectTitle {
    if (selectedSubjectId.value == null) return 'All Challenges';
    final subj = studentSubjects.firstWhereOrNull((s) => s.id == selectedSubjectId.value);
    return subj != null ? '${subj.name} Challenges' : (subjectTitle ?? 'Challenges');
  }

  List<LeaderboardChallengeModel> get displayedChallenges {
    if (selectedSubjectId.value == null) {
      return challenges;
    }
    return challenges
        .where((c) => c.subjectId == selectedSubjectId.value)
        .toList();
  }

  void selectSubject(int? id) {
    selectedSubjectId.value = id;
  }

  int countForSubject(int? subjId) {
    if (subjId == null) return challenges.length;
    return challenges.where((c) => c.subjectId == subjId).length;
  }

  @override
  void onInit() {
    super.onInit();
    _preloadLocalArchivedChallenges();
    loadArchive();
    _startRealtime();
    ever(UserController.instance.user, (_) => loadArchive(isManual: false));
  }

  @override
  void onClose() {
    if (_realtimeChannel != null) {
      _sb.removeChannel(_realtimeChannel!);
    }
    super.onClose();
  }

  void _startRealtime() {
    if (_realtimeChannel != null) {
      _sb.removeChannel(_realtimeChannel!);
    }
    final tag = subjectId != null ? 'archive_$subjectId' : 'archive_all';
    _realtimeChannel = _sb
        .channel('public:challenge_archive_$tag')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'leaderboard_challenges',
          callback: (payload) {
            debugPrint(
              '[Realtime] Archive challenge changed: ${payload.eventType}',
            );
            loadArchive(isManual: false);
          },
        )
        .subscribe((status, [error]) {
          debugPrint(
            '[Realtime] Archive channel status: $status ${error ?? ''}',
          );
        });
  }

  Future<void> _preloadLocalArchivedChallenges() async {
    final local = await _loadLocalArchivedChallenges();
    if (local.isNotEmpty && challenges.isEmpty) {
      challenges.assignAll(local);
      await refreshDownloadStates();
      await refreshAttemptStates();
    }
  }

  Future<void> _saveCachedArchiveChallenges(List<LeaderboardChallengeModel> list) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tag = subjectId != null ? 'archive_$subjectId' : 'archive_all';
      final jsonList = list.map((c) => c.toJson()).toList();
      final encoded = jsonEncode(jsonList);
      await prefs.setString('cached_$tag', encoded);
      if (userStream.isNotEmpty) {
        await prefs.setString('cached_${tag}_$userStream', encoded);
      }
    } catch (_) {}
  }

  Future<List<LeaderboardChallengeModel>> _getCachedArchiveChallenges() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tag = subjectId != null ? 'archive_$subjectId' : 'archive_all';
      String? str;
      if (userStream.isNotEmpty) {
        str = prefs.getString('cached_${tag}_$userStream');
      }
      str ??= prefs.getString('cached_$tag');

      // If subject archive cache is empty, fallback to main all-challenges cache filtered by subject
      if ((str == null || str.isEmpty) && subjectId != null) {
        if (userStream.isNotEmpty) {
          str = prefs.getString('cached_all_challenges_$userStream');
        }
        str ??= prefs.getString('cached_all_challenges');
        str ??= prefs.getString('cached_closed_challenges_$userStream');
        str ??= prefs.getString('cached_closed_challenges');
      }

      if (str == null || str.isEmpty) return [];
      final List decoded = jsonDecode(str);
      final list = decoded
          .map((j) => LeaderboardChallengeModel.fromJson(j as Map<String, dynamic>))
          .toList();
      if (subjectId != null) {
        return list.where((c) => c.subjectId == subjectId).toList();
      }
      return list;
    } catch (_) {
      return [];
    }
  }

  Future<List<LeaderboardChallengeModel>> _loadLocalArchivedChallenges() async {
    try {
      final subjectsList = Get.isRegistered<SubjectsController>()
          ? SubjectsController.instance.subjects
          : [];
      final isNatural = userStream == 'natural';
      final Map<String, LeaderboardChallengeModel> challengeMap = {};

      // 1. Load previously cached challenges
      final cachedList = await _getCachedArchiveChallenges();
      for (final c in cachedList) {
        // When offline, only closed or archived challenges can be practiced/reviewed
        if (!c.isClosed && !c.isArchived) continue;

        final aud = c.audience.toLowerCase().trim();
        final matchesAud = userStream.isEmpty || aud == 'both' || aud == userStream;
        if (!matchesAud) continue;

        if (subjectsList.isNotEmpty && userStream.isNotEmpty) {
          final subj = subjectsList.firstWhereOrNull((s) => s.id == c.subjectId);
          if (subj != null) {
            final matchesSubj = subj.isCommon || (isNatural ? subj.isNatural : !subj.isNatural);
            if (!matchesSubj) continue;
          }
        }
        challengeMap[c.id] = c;
      }

      // 2. Load downloaded challenge sets from SQLite
      final rows = await _db.getDownloadedChallengeSets(subjectId: subjectId);
      for (final r in rows) {
        final cId = r['challenge_id']?.toString() ?? r['id']?.toString() ?? '';
        final sId = (r['subject_id'] as num?)?.toInt() ?? 0;
        final title = r['title']?.toString() ?? 'Challenge Set';
        final aud = (r['audience']?.toString() ?? 'both').toLowerCase().trim();

        final matchesAud = userStream.isEmpty || aud == 'both' || aud == userStream;
        if (!matchesAud) continue;

        if (subjectsList.isNotEmpty && userStream.isNotEmpty) {
          final subj = subjectsList.firstWhereOrNull((s) => s.id == sId);
          if (subj != null) {
            final matchesSubj = subj.isCommon || (isNatural ? subj.isNatural : !subj.isNatural);
            if (!matchesSubj) continue;
          }
        }

        final qRows = await _db.getDownloadedChallengeQuestions(cId);

        String? subjName;
        if (subjectsList.isNotEmpty) {
          final subj = subjectsList.firstWhereOrNull((s) => s.id == sId);
          subjName = subj?.name;
        }

        challengeMap[cId] = LeaderboardChallengeModel(
          id: cId,
          setId: cId,
          title: title,
          subjectId: sId,
          subjectName: subjName ?? challengeMap[cId]?.subjectName ?? subjectTitle ?? 'Subject',
          audience: aud,
          questionCount: qRows.isNotEmpty ? qRows.length : (challengeMap[cId]?.questionCount ?? 0),
          status: 'closed',
          createdAt: DateTime.now(),
        );
      }

      return challengeMap.values.toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> loadArchive({bool isManual = false}) async {
    if (isManual) {
      isManualRefreshing.value = true;
    } else if (challenges.isEmpty) {
      isLoading.value = true;
    }
    try {
      // Fetch all challenges across subjects for student stream so tabs work seamlessly
      final list = await _repo.fetchAllSubjectChallenges(stream: userStream);
      final isNatural = userStream == 'natural';

      final subjectsList = Get.isRegistered<SubjectsController>()
          ? SubjectsController.instance.subjects
          : [];

      final filtered = list.where((c) {
        final aud = c.audience.toLowerCase().trim();
        final matchesAudience = aud == 'both' || aud == userStream || userStream.isEmpty;
        if (!matchesAudience) return false;

        if (subjectsList.isNotEmpty) {
          final subj = subjectsList.firstWhereOrNull((s) => s.id == c.subjectId);
          if (subj != null) {
            return subj.isCommon || (isNatural ? subj.isNatural : !subj.isNatural);
          }
        }
        return true;
      }).toList();

      challenges.value = filtered;
      isOffline.value = false;
      _saveCachedArchiveChallenges(filtered);
      await refreshDownloadStates();
      await refreshAttemptStates();

      if (isManual) {
        ToastHelper.success('Refreshed successfully');
      }
    } catch (e) {
      isOffline.value = true;
      // Fallback to local DB when offline or network fails
      final localChallenges = await _loadLocalArchivedChallenges();
      if (localChallenges.isNotEmpty || challenges.isEmpty) {
        challenges.value = localChallenges;
      }
      await refreshDownloadStates();
      await refreshAttemptStates();

      if (isManual) {
        ToastHelper.warning('No internet connection. Showing offline data.');
      }
    } finally {
      isLoading.value = false;
      isManualRefreshing.value = false;
    }
  }

  Future<void> manualRefresh() => loadArchive(isManual: true);

  Future<void> refreshDownloadStates() async {
    final downloaded = <String>{};
    for (final c in challenges) {
      final isDown = await _db.isChallengeDownloaded(c.id, setId: c.setId);
      if (isDown) downloaded.add(c.id);
    }
    downloadedIds.assignAll(downloaded);
  }

  Future<void> refreshAttemptStates() async {
    try {
      final local = await _db.getCompletedPracticeChallengeIds();
      attemptedIds.addAll(local);

      final userId = UserController.instance.user.value.id;
      if (userId.isNotEmpty) {
        final online = await _repo.fetchUserSubmittedChallengeIds(userId);
        attemptedIds.addAll(online);
      }
    } catch (_) {}
  }

  bool isDownloaded(String challengeId) => downloadedIds.contains(challengeId);
  bool isAttemptedOrPracticed(String challengeId) => attemptedIds.contains(challengeId);

  void markAttemptedOrPracticed(String challengeId) {
    attemptedIds.add(challengeId);
  }

  Future<void> downloadChallenge(LeaderboardChallengeModel challenge) async {
    if (!isPremium) {
      Get.bottomSheet(const PremiumBottomSheet(), isScrollControlled: true);
      return;
    }

    try {
      isDownloading[challenge.id] = true;
      final userId = UserController.instance.user.value.id;

      final bundle = await _repo.fetchChallengeBundle(
        challengeId: challenge.id,
        userId: userId,
      );

      await _db.insertDownloadedChallengeBundle(bundle);
      downloadedIds.add(challenge.id);
      if (Get.isRegistered<ChallengeHomeController>()) {
        Get.find<ChallengeHomeController>().downloadedIds.add(challenge.id);
      }
      ToastHelper.success('Downloaded for offline practice!');
    } catch (e) {
      // Fallback to local DB when offline or network fails
      final localChallenges = await _loadLocalArchivedChallenges();
      if (localChallenges.isNotEmpty) {
        challenges.value = localChallenges;
        await refreshDownloadStates();
        await refreshAttemptStates();
      } else {
        AppExceptionHandler.handleResponse(e);
      }
    } finally {
      isDownloading[challenge.id] = false;
    }
  }

  Future<void> confirmDeleteDownload(BuildContext context, LeaderboardChallengeModel challenge) async {
    final isDone = isAttemptedOrPracticed(challenge.id);
    final isDown = isDownloaded(challenge.id);

    final titleText = isDown && isDone
        ? 'Delete Challenge Data'
        : isDone
            ? 'Delete Challenge Practice Data'
            : 'Delete Downloaded Challenge';

    final contentText = isDown && isDone
        ? 'Are you sure you want to remove "${challenge.title}" offline bundle and local practice data from this device?'
        : isDone
            ? 'Are you sure you want to remove your local practice record for "${challenge.title}" from this device?'
            : 'Are you sure you want to remove "${challenge.title}" offline data from this device?';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(titleText),
        content: Text(contentText),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _db.deleteDownloadedChallenge(challenge.id, setId: challenge.setId);
        await _db.deleteChallengePracticeResult(challenge.id, setId: challenge.setId);
        downloadedIds.remove(challenge.id);
        attemptedIds.remove(challenge.id);
        if (Get.isRegistered<ChallengeHomeController>()) {
          final hCtrl = Get.find<ChallengeHomeController>();
          hCtrl.downloadedIds.remove(challenge.id);
          hCtrl.attemptedIds.remove(challenge.id);
          if (hCtrl.isOffline.value) {
            hCtrl.completedChallenges.removeWhere((c) => c.id == challenge.id);
          }
        }
        if (isOffline.value) {
          challenges.removeWhere((c) => c.id == challenge.id);
        }
        ToastHelper.info('Challenge data removed from device.');
      } catch (e) {
        AppExceptionHandler.handleResponse(e);
      }
    }
  }

  Future<void> openCompletedChallenge(LeaderboardChallengeModel challenge) async {
    if (isOpeningReview[challenge.id] == true) return;
    isOpeningReview[challenge.id] = true;
    try {
      final userId = UserController.instance.user.value.id.isNotEmpty
          ? UserController.instance.user.value.id
          : (FirebaseAuth.instance.currentUser?.uid ?? '');

      // 1. Check local practice results first (fastest & offline)
      final localPractice = await _db.getChallengePracticeResult(challenge.id, setId: challenge.setId);
      if (localPractice != null) {
        final answersStr = localPractice['user_answers']?.toString() ?? '{}';
        Map<String, String> userAnswers = {};
        try {
          final decoded = jsonDecode(answersStr) as Map<String, dynamic>;
          userAnswers = decoded.map((k, v) => MapEntry(k, v.toString()));
        } catch (_) {}

        List<ChallengeQuestionModel> questions = [];
        final localRows = await _db.getDownloadedChallengeQuestions(challenge.id, setId: challenge.setId);
        if (localRows.isNotEmpty) {
          questions = localRows.map((r) => ChallengeQuestionModel.fromJson(r)).toList();
        } else {
          try {
            questions = await _repo.fetchQuestionsForReview(challenge.id, setId: challenge.setId);
            if (questions.isNotEmpty) {
              await _db.insertDownloadedChallengeBundle({
                'id': challenge.id,
                'challenge_id': challenge.id,
                'set_id': challenge.setId,
                'subject_id': challenge.subjectId,
                'title': challenge.title,
                'audience': challenge.audience,
                'questions': questions.map((q) => q.toJson()).toList(),
              });
            }
          } catch (_) {}
        }

        if (questions.isNotEmpty) {
          Get.to(
            () => ChallengeReviewScreen(
              challengeId: challenge.id,
              title: challenge.title,
              audience: challenge.audience,
              questions: questions,
              userAnswers: userAnswers,
              score: (localPractice['score'] as num?)?.toInt() ?? 0,
              timeSpentSeconds: (localPractice['time_spent_seconds'] as num?)?.toInt() ?? 0,
            ),
          );
          return;
        }
      }

      // 2. Check online submitted attempt
      if (userId.isNotEmpty) {
        final attemptData = await _repo.fetchUserAttempt(
          challengeId: challenge.id,
          userId: userId,
        );

        if (attemptData != null) {
          final attempt = attemptData['attempt'] as ChallengeAttemptModel;
          final userAnswers = attemptData['user_answers'] as Map<String, String>;

          List<ChallengeQuestionModel> questions = [];
          final localRows = await _db.getDownloadedChallengeQuestions(challenge.id, setId: challenge.setId);
          if (localRows.isNotEmpty) {
            questions = localRows.map((r) => ChallengeQuestionModel.fromJson(r)).toList();
          } else {
            questions = await _repo.fetchQuestionsForReview(challenge.id, setId: challenge.setId);
          }

          if (questions.isNotEmpty) {
            // Cache to local practice DB & SQLite question bundle for instant subsequent review
            await _db.saveChallengePracticeResult(
              challengeId: challenge.id,
              score: attempt.score,
              totalQuestions: questions.length,
              userAnswers: userAnswers,
              timeSpentSeconds: attempt.totalTimeSeconds,
            );

            await _db.insertDownloadedChallengeBundle({
              'id': challenge.id,
              'challenge_id': challenge.id,
              'set_id': challenge.setId,
              'subject_id': challenge.subjectId,
              'title': challenge.title,
              'audience': challenge.audience,
              'questions': questions.map((q) => q.toJson()).toList(),
            });

            Get.to(
              () => ChallengeReviewScreen(
                challengeId: challenge.id,
                title: challenge.title,
                audience: challenge.audience,
                questions: questions,
                userAnswers: userAnswers,
                score: attempt.score,
                timeSpentSeconds: attempt.totalTimeSeconds,
              ),
            );
            return;
          }
        }
      }

      ToastHelper.warning('No completed attempt found to review.');
    } catch (e) {
      ToastHelper.error('Could not load review. Please check your connection.');
    } finally {
      isOpeningReview[challenge.id] = false;
    }
  }
}
