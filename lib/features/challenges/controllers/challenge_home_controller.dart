import 'package:matricmate/features/exam/models/subject_model.dart';
import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matricmate/common/widgets/exam/premium_bottom_sheet.dart';
import 'package:matricmate/data/database/database_service.dart';
import 'package:matricmate/data/repositories/challenge/challenge_repository.dart';
import 'package:matricmate/features/challenges/models/challenge_attempt_model.dart';
import 'package:matricmate/features/challenges/models/challenge_model.dart';
import 'package:matricmate/features/challenges/models/challenge_question_model.dart';
import 'package:matricmate/features/challenges/screens/challenge_attempt_screen.dart';
import 'package:matricmate/features/challenges/screens/challenge_practice_screen.dart';
import 'package:matricmate/features/challenges/screens/challenge_review_screen.dart';
import 'package:matricmate/features/exam/controllers/subjects_controller.dart';
import 'package:matricmate/features/personalization/controllers/user_controller.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/exceptions/exception_handler.dart';
import 'package:matricmate/utils/helpers/toast_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChallengeHomeController extends GetxController {
  static ChallengeHomeController get instance => Get.find();

  final _repo = ChallengeRepository();
  final _db = DatabaseService.instance;
  final _sb = Supabase.instance.client;

  final isLoading = false.obs;
  final isRefreshing = false.obs;
  final availableChallenges = <LeaderboardChallengeModel>[].obs;
  final completedChallenges = <LeaderboardChallengeModel>[].obs;

  final downloadedIds = <String>{}.obs;
  final isDownloading = <String, bool>{}.obs;
  final attemptedIds = <String>{}.obs;
  final selectedCompletedSubjectId = RxnInt(); // null = Recent 3 (default)
  final selectedTabIndex = 0.obs;
  final isOffline = false.obs;

  void switchTab(int index) {
    selectedTabIndex.value = index;
  }

  List<SubjectModel> get studentSubjects {
    final isNatural = userStream.toLowerCase().trim() == 'natural';
    if (Get.isRegistered<SubjectsController>()) {
      return SubjectsController.instance.subjects.where((s) {
        return s.isCommon || (isNatural ? s.isNatural : !s.isNatural);
      }).toList();
    }
    return [];
  }

  List<LeaderboardChallengeModel> get recentCompletedChallenges =>
      completedChallenges.take(3).toList();

  List<LeaderboardChallengeModel> get displayedCompletedChallenges {
    if (selectedCompletedSubjectId.value == null) {
      return completedChallenges;
    }
    return completedChallenges
        .where((c) => c.subjectId == selectedCompletedSubjectId.value)
        .toList();
  }

  void selectCompletedSubject(int? subjectId) {
    if (selectedCompletedSubjectId.value == subjectId) {
      selectedCompletedSubjectId.value = null;
    } else {
      selectedCompletedSubjectId.value = subjectId;
    }
  }


  final now = DateTime.now().obs;

  Timer? _countdownTimer;
  RealtimeChannel? _realtimeChannel;

  bool get isPremium => UserController.instance.user.value.isActive;
  String get userStream => UserController.instance.user.value.stream;

  @override
  void onInit() {
    super.onInit();
    _preloadLocalChallenges();
    loadAllChallenges();
    _startTimer();
    _startRealtime();

    ever(UserController.instance.user, (_) => loadAllChallenges(showLoading: false));
  }

  @override
  void onClose() {
    _countdownTimer?.cancel();
    if (_realtimeChannel != null) {
      _sb.removeChannel(_realtimeChannel!);
    }
    super.onClose();
  }

  void _startTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      now.value = DateTime.now();
      _checkTimeTransitions();
    });
  }

  void _checkTimeTransitions() {
    bool stateChanged = false;
    final currentTime = now.value;

    // 1. Check if any available challenge has now closed (endsAt passed)
    final newlyClosed = <LeaderboardChallengeModel>[];
    final remainingAvailable = <LeaderboardChallengeModel>[];

    for (final c in availableChallenges) {
      if (c.endsAt != null && currentTime.isAfter(c.endsAt!)) {
        newlyClosed.add(c);
        stateChanged = true;
      } else {
        remainingAvailable.add(c);
      }
    }

    if (newlyClosed.isNotEmpty) {
      availableChallenges.assignAll(remainingAvailable);
      for (final c in newlyClosed) {
        if (!completedChallenges.any((item) => item.id == c.id)) {
          completedChallenges.insert(0, c);
        }
      }
      return;
    }

    // 2. Check if any scheduled challenge crossed into live (startsAt passed)
    for (final c in availableChallenges) {
      if (c.startsAt != null &&
          c.status == 'scheduled' &&
          !currentTime.isBefore(c.startsAt!)) {
        stateChanged = true;
        break;
      }
    }

    if (stateChanged) {
      availableChallenges.refresh();
    }
  }

  void _startRealtime() {
    if (_realtimeChannel != null) {
      _sb.removeChannel(_realtimeChannel!);
    }
    _realtimeChannel = _sb
        .channel('public:leaderboard_challenges')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'leaderboard_challenges',
          callback: (payload) {
            debugPrint('[Realtime] Challenge changed: ${payload.eventType}');
            loadAllChallenges(showLoading: false);
          },
        )
        .subscribe((status, [error]) {
          debugPrint('[Realtime] Challenges status: $status ${error ?? ''}');
        });
  }

  Future<void> _preloadLocalChallenges() async {
    final local = await _loadLocalChallenges();
    if (local.isNotEmpty && completedChallenges.isEmpty) {
      completedChallenges.assignAll(local);
      await refreshDownloadStates();
      await refreshAttemptStates();
    }
  }

  Future<void> _saveCachedChallenges(List<LeaderboardChallengeModel> list) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final streamTag = userStream.toLowerCase().trim();
      final jsonList = list.map((c) => c.toJson()).toList();
      final encoded = jsonEncode(jsonList);
      await prefs.setString('cached_all_challenges', encoded);
      if (streamTag.isNotEmpty) {
        await prefs.setString('cached_all_challenges_$streamTag', encoded);
      }
    } catch (_) {}
  }

  Future<List<LeaderboardChallengeModel>> _getCachedChallenges() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final streamTag = userStream.toLowerCase().trim();
      String? str;
      if (streamTag.isNotEmpty) {
        str = prefs.getString('cached_all_challenges_$streamTag');
      }
      str ??= prefs.getString('cached_all_challenges');
      str ??= prefs.getString('cached_closed_challenges_$streamTag');
      str ??= prefs.getString('cached_closed_challenges');
      if (str == null || str.isEmpty) return [];
      final List decoded = jsonDecode(str);
      return decoded
          .map((j) => LeaderboardChallengeModel.fromJson(j as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<LeaderboardChallengeModel>> _loadLocalChallenges() async {
    try {
      final subjectsList = Get.isRegistered<SubjectsController>()
          ? SubjectsController.instance.subjects
          : [];
      final streamTag = userStream.toLowerCase().trim();
      final isNatural = streamTag == 'natural';
      final Map<String, LeaderboardChallengeModel> challengeMap = {};

      // 1. Load previously cached challenges
      final cachedList = await _getCachedChallenges();
      for (final c in cachedList) {
        final aud = c.audience.toLowerCase().trim();
        final matchesAud = streamTag.isEmpty || aud == 'both' || aud == streamTag;
        if (!matchesAud) continue;

        if (subjectsList.isNotEmpty && streamTag.isNotEmpty) {
          final subj = subjectsList.firstWhereOrNull((s) => s.id == c.subjectId);
          if (subj != null) {
            final matchesSubj = subj.isCommon || (isNatural ? subj.isNatural : !subj.isNatural);
            if (!matchesSubj) continue;
          }
        }
        challengeMap[c.id] = c;
      }

      // 2. Load downloaded challenge sets from SQLite (with actual question sets)
      final rows = await _db.getDownloadedChallengeSets();
      for (final r in rows) {
        final cId = r['challenge_id']?.toString() ?? r['id']?.toString() ?? '';
        final sId = (r['subject_id'] as num?)?.toInt() ?? 0;
        final title = r['title']?.toString() ?? 'Challenge Set';
        final aud = (r['audience']?.toString() ?? 'both').toLowerCase().trim();

        final matchesAud = streamTag.isEmpty || aud == 'both' || aud == streamTag;
        if (!matchesAud) continue;

        if (subjectsList.isNotEmpty && streamTag.isNotEmpty) {
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
          subjectName: subjName ?? challengeMap[cId]?.subjectName ?? 'Subject',
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

  Future<void> loadAllChallenges({bool showLoading = true, bool isManual = false}) async {
    if (showLoading && completedChallenges.isEmpty && availableChallenges.isEmpty) {
      isLoading.value = true;
    }
    isRefreshing.value = true;
    try {
      final streamTag = userStream.toLowerCase().trim();
      final isNatural = streamTag == 'natural';
      final subjectsList = Get.isRegistered<SubjectsController>()
          ? SubjectsController.instance.subjects
          : [];

      // 1. Fetch available & live challenges
      final visibleList = await _repo.fetchVisibleChallenges(stream: userStream);
      final filteredAvailable = visibleList.where((c) {
        if (c.isClosed || c.isArchived) return false;
        final aud = c.audience.toLowerCase().trim();
        final matchesAudience = streamTag.isEmpty || aud == 'both' || aud == streamTag;
        if (!matchesAudience) return false;

        if (subjectsList.isNotEmpty && streamTag.isNotEmpty) {
          final subj = subjectsList.firstWhereOrNull((s) => s.id == c.subjectId);
          if (subj != null) {
            return subj.isCommon || (isNatural ? subj.isNatural : !subj.isNatural);
          }
        }
        return true;
      }).toList();

      availableChallenges.value = filteredAvailable;

      // 2. Fetch completed / closed challenges
      final closedList = await _repo.fetchClosedChallenges(stream: userStream);
      final filteredClosed = closedList.where((c) {
        final aud = c.audience.toLowerCase().trim();
        final matchesAudience = streamTag.isEmpty || aud == 'both' || aud == streamTag;
        if (!matchesAudience) return false;

        if (subjectsList.isNotEmpty && streamTag.isNotEmpty) {
          final subj = subjectsList.firstWhereOrNull((s) => s.id == c.subjectId);
          if (subj != null) {
            return subj.isCommon || (isNatural ? subj.isNatural : !subj.isNatural);
          }
        }
        return true;
      }).toList();

      completedChallenges.value = filteredClosed;
      isOffline.value = false;

      // Cache all valid challenges (both available and closed) for offline resilience
      final allChallenges = [...filteredAvailable, ...filteredClosed];
      _saveCachedChallenges(allChallenges);

      // 3. Prune deleted/stale challenge sets from local SQLite storage
      final validServerIds = <String>{
        ...visibleList.map((c) => c.id),
        ...closedList.map((c) => c.id),
      };
      await _db.pruneDeletedChallengeSets(validServerIds);

      // 4. Refresh offline download states
      await refreshDownloadStates();
      await refreshAttemptStates();

      if (isManual) {
        ToastHelper.success('Challenges refreshed!');
      }
    } catch (e) {
      isOffline.value = true;
      availableChallenges.clear();
      final local = await _loadLocalChallenges();
      completedChallenges.assignAll(local);
      await refreshDownloadStates();
      await refreshAttemptStates();

      if (isManual) {
        ToastHelper.warning('No internet connection. Showing offline data.');
      }
    } finally {
      isLoading.value = false;
      isRefreshing.value = false;
    }
  }

  Future<void> refreshDownloadStates() async {
    final downloaded = <String>{};
    for (final c in [...availableChallenges, ...completedChallenges]) {
      final isDown = await _db.isChallengeDownloaded(c.id, setId: c.setId);
      if (isDown) downloaded.add(c.id);
    }
    downloadedIds.assignAll(downloaded);
  }

  bool isDownloaded(String challengeId) => downloadedIds.contains(challengeId);

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
      ToastHelper.success('Downloaded for offline practice!');
    } catch (e) {
      AppExceptionHandler.handleResponse(e);
    } finally {
      isDownloading[challenge.id] = false;
    }
  }

  Future<void> confirmDeleteDownload(BuildContext context, LeaderboardChallengeModel challenge) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Downloaded Challenge'),
        content: Text('Are you sure you want to remove "${challenge.title}" offline data and local practice from this device?'),
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
        downloadedIds.remove(challenge.id);
        attemptedIds.remove(challenge.id);
        ToastHelper.info('Removed offline download.');
      } catch (e) {
        AppExceptionHandler.handleResponse(e);
      }
    }
  }

  String formatCountdown(DateTime target) {
    final current = now.value;
    final diff = target.difference(current);
    if (diff.isNegative) return 'Starting now...';

    final hours = diff.inHours;
    final minutes = diff.inMinutes % 60;
    final seconds = diff.inSeconds % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  void onChallengeTapped(LeaderboardChallengeModel challenge) {
    if (!isPremium) {
      Get.bottomSheet(
        const PremiumBottomSheet(),
        isScrollControlled: true,
      );
      return;
    }

    if (isAttemptedOrPracticed(challenge.id)) {
      openCompletedChallenge(challenge);
      return;
    }

    if (challenge.isLive) {
      Get.to(
        () => ChallengeAttemptScreen(
          challengeId: challenge.id,
          title: challenge.title,
          audience: challenge.audience,
        ),
      );
    } else if (challenge.isScheduled) {
      if (challenge.startsAt != null) {
        ToastHelper.info(
          'Opens in ${formatCountdown(challenge.startsAt!)}. Get ready!',
        );
      } else {
        ToastHelper.info('This challenge has not started yet.');
      }
    } else if (challenge.isClosed || challenge.isArchived) {
      Get.to(() => ChallengePracticeScreen(challengeId: challenge.id, title: challenge.title));
    }
  }

  
  void markAttemptedOrPracticed(String challengeId) {
    attemptedIds.add(challengeId);
  }

  bool isAttemptedOrPracticed(String challengeId) => attemptedIds.contains(challengeId);

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

    Future<void> openCompletedChallenge(LeaderboardChallengeModel challenge) async {
    try {
      final userId = UserController.instance.user.value.id;

      // 1. Check local practice results first (fastest)
      final localPractice = await _db.getChallengePracticeResult(challenge.id);
      if (localPractice != null) {
        final answersStr = localPractice['user_answers']?.toString() ?? '{}';
        Map<String, String> userAnswers = {};
        try {
          final decoded = jsonDecode(answersStr) as Map<String, dynamic>;
          userAnswers = decoded.map((k, v) => MapEntry(k, v.toString()));
        } catch (_) {}

        List<ChallengeQuestionModel> questions = [];
        final localRows = await _db.getDownloadedChallengeQuestions(challenge.id);
        if (localRows.isNotEmpty) {
          questions = localRows.map((r) => ChallengeQuestionModel.fromJson(r)).toList();
        } else {
          questions = await _repo.fetchQuestionsForReview(challenge.id);
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
          final localRows = await _db.getDownloadedChallengeQuestions(challenge.id);
          if (localRows.isNotEmpty) {
            questions = localRows.map((r) => ChallengeQuestionModel.fromJson(r)).toList();
          } else {
            questions = await _repo.fetchQuestionsForReview(challenge.id);
          }

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

      // 3. Fallback to Practice mode
      Get.to(
        () => ChallengePracticeScreen(
          challengeId: challenge.id,
          title: challenge.title,
          setId: challenge.setId,
        ),
      );
    } catch (_) {
      Get.to(
        () => ChallengePracticeScreen(
          challengeId: challenge.id,
          title: challenge.title,
          setId: challenge.setId,
        ),
      );
    }
  }
}