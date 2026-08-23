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
  static ChallengeArchiveController get instance => Get.find();

  final _repo = ChallengeRepository();
  final _db = DatabaseService.instance;

  final isLoading = false.obs;
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
  }

  Future<void> loadArchive() async {
    isLoading.value = true;
    try {
      final list = await _repo.fetchClosedChallenges(stream: userStream);
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
      await refreshDownloadStates();
      await refreshAttemptStates();
    } catch (e) {
      AppExceptionHandler.handleResponse(e);
    } finally {
      isLoading.value = false;
    }
  }

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
      AppExceptionHandler.handleResponse(e);
    } finally {
      isDownloading[challenge.id] = false;
    }
  }

  Future<void> deleteDownload(LeaderboardChallengeModel challenge) async {
    try {
      await _db.deleteDownloadedChallenge(challenge.id);
      downloadedIds.remove(challenge.id);
      ToastHelper.info('Download removed.');
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
