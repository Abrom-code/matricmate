import 'dart:convert';
import 'package:get/get.dart';
import 'package:matricmate/common/widgets/exam/premium_bottom_sheet.dart';
import 'package:matricmate/data/database/database_service.dart';
import 'package:matricmate/data/repositories/challenge/challenge_repository.dart';
import 'package:matricmate/features/challenges/models/challenge_attempt_model.dart';
import 'package:matricmate/features/challenges/models/challenge_model.dart';
import 'package:matricmate/features/challenges/models/challenge_question_model.dart';
import 'package:matricmate/features/challenges/screens/challenge_practice_screen.dart';
import 'package:matricmate/features/challenges/screens/challenge_review_screen.dart';
import 'package:matricmate/features/exam/controllers/subjects_controller.dart';
import 'package:matricmate/features/personalization/controllers/user_controller.dart';
import 'package:matricmate/utils/exceptions/exception_handler.dart';
import 'package:matricmate/utils/helpers/toast_helper.dart';

class ChallengeArchiveController extends GetxController {
  ChallengeArchiveController({this.subjectId, this.subjectTitle});

  static ChallengeArchiveController get instance => Get.find();

  final int? subjectId;
  final String? subjectTitle;

  final _repo = ChallengeRepository();
  final _db = DatabaseService.instance;

  final isLoading = false.obs;
  final isManualRefreshing = false.obs;
  final challenges = <LeaderboardChallengeModel>[].obs;
  final downloadedIds = <String>{}.obs;
  final isDownloading = <String, bool>{}.obs;
  final attemptedIds = <String>{}.obs;

  bool get isPremium => UserController.instance.user.value.isActive;
  String get userStream => UserController.instance.user.value.stream.toLowerCase().trim();

  @override
  void onInit() {
    super.onInit();
    loadArchive();
    ever(UserController.instance.user, (_) => loadArchive(isManual: false));
  }

    Future<List<LeaderboardChallengeModel>> _loadLocalArchivedChallenges() async {
    try {
      final rows = await _db.getDownloadedChallengeSets(subjectId: subjectId);
      final subjectsList = Get.isRegistered<SubjectsController>()
          ? SubjectsController.instance.subjects
          : [];

      final list = <LeaderboardChallengeModel>[];
      final isNatural = userStream == 'natural';
      for (final r in rows) {
        final cId = r['challenge_id']?.toString() ?? r['id']?.toString() ?? '';
        final sId = (r['subject_id'] as num?)?.toInt() ?? 0;
        final title = r['title']?.toString() ?? 'Challenge Set';
        final aud = (r['audience']?.toString() ?? 'both').toLowerCase().trim();

        final matchesAud = aud == 'both' || aud == userStream || userStream.isEmpty;
        if (!matchesAud) continue;

        if (subjectsList.isNotEmpty) {
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

        list.add(
          LeaderboardChallengeModel(
            id: cId,
            setId: cId,
            title: title,
            subjectId: sId,
            subjectName: subjName ?? subjectTitle ?? 'Subject',
            audience: aud,
            questionCount: qRows.length,
            status: 'closed',
            createdAt: DateTime.now(),
          ),
        );
      }
      return list;
    } catch (_) {
      return [];
    }
  }

  Future<void> loadArchive({bool isManual = false}) async {
    if (isManual) {
      isManualRefreshing.value = true;
    } else {
      isLoading.value = true;
    }
    try {
      final list = await _repo.fetchClosedChallenges(stream: userStream);
      final isNatural = userStream == 'natural';

      final subjectsList = Get.isRegistered<SubjectsController>()
          ? SubjectsController.instance.subjects
          : [];

      final filtered = list.where((c) {
        if (subjectId != null && c.subjectId != subjectId) return false;

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
      await refreshDownloadStates();
      await refreshAttemptStates();
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
      isLoading.value = false;
      isManualRefreshing.value = false;
    }
  }

  Future<void> manualRefresh() => loadArchive(isManual: true);

  Future<void> refreshDownloadStates() async {
    final downloaded = <String>{};
    for (final c in challenges) {
      final isDown = await _db.isChallengeDownloaded(c.id);
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

  Future<void> deleteDownload(LeaderboardChallengeModel challenge) async {
    try {
      await _db.deleteDownloadedChallenge(challenge.id);
      downloadedIds.remove(challenge.id);
      attemptedIds.remove(challenge.id);
      ToastHelper.info('Removed local data.');
    } catch (e) {
      AppExceptionHandler.handleResponse(e);
    }
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
