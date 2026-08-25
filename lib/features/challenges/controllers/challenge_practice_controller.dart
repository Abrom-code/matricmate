import 'dart:convert';
import 'package:get/get.dart';
import 'package:matricmate/data/database/database_service.dart';
import 'package:matricmate/data/repositories/challenge/challenge_repository.dart';
import 'package:matricmate/features/challenges/controllers/challenge_archive_controller.dart';
import 'package:matricmate/features/challenges/controllers/challenge_home_controller.dart';
import 'package:matricmate/features/challenges/models/challenge_question_model.dart';
import 'package:matricmate/features/challenges/screens/challenge_review_screen.dart';
import 'package:matricmate/utils/exceptions/exception_handler.dart';

class ChallengePracticeController extends GetxController {
  ChallengePracticeController({
    required this.challengeId,
    required this.title,
    this.setId,
  });

  final String challengeId;
  final String title;
  final String? setId;

  final _db = DatabaseService.instance;
  final _repo = ChallengeRepository();

  final isLoading = true.obs;
  final questions = <ChallengeQuestionModel>[].obs;
  final currentIndex = 0.obs;

  // Selected answers: { question_id: selected_choice_index_or_text }
  final userAnswers = <String, String>{}.obs;
  final stopwatch = Stopwatch();

  int get totalQuestions => questions.length;
  ChallengeQuestionModel get currentQuestion => questions[currentIndex.value];

  @override
  void onInit() {
    super.onInit();
    stopwatch.start();
    loadQuestions();
  }

  @override
  void onClose() {
    stopwatch.stop();
    super.onClose();
  }

  Future<void> loadQuestions() async {
    isLoading.value = true;
    try {
      final rows = await _db.getDownloadedChallengeQuestions(challengeId);
      if (rows.isNotEmpty) {
        questions.value = rows
            .map((r) => ChallengeQuestionModel.fromJson(r))
            .toList();
      } else {
        // Fallback to online repository if not downloaded
        questions.value = await _repo.fetchQuestionsForReview(challengeId);
      }

      // Check if past practice exists to restore answers
      final pastPractice = await _db.getChallengePracticeResult(challengeId);
      if (pastPractice != null) {
        final answersStr = pastPractice['user_answers']?.toString() ?? '{}';
        try {
          final decoded = jsonDecode(answersStr) as Map<String, dynamic>;
          userAnswers.assignAll(decoded.map((k, v) => MapEntry(k, v.toString())));
        } catch (_) {}
      }
    } catch (e) {
      AppExceptionHandler.handleResponse(e);
    } finally {
      isLoading.value = false;
    }
  }

  void selectOption(String choice) {
    if (userAnswers.containsKey(currentQuestion.id)) return; // Lock after picking for instant feedback
    userAnswers[currentQuestion.id] = choice;
  }

  void nextQuestion() {
    if (currentIndex.value < totalQuestions - 1) {
      currentIndex.value++;
    }
  }

  void prevQuestion() {
    if (currentIndex.value > 0) {
      currentIndex.value--;
    }
  }

  void goToQuestion(int index) {
    if (index >= 0 && index < totalQuestions) {
      currentIndex.value = index;
    }
  }

  Future<void> finishPracticeAndReview() async {
    // Calculate score
    int correctCount = 0;
    for (final q in questions) {
      final ans = userAnswers[q.id];
      if (ans != null && ans.isNotEmpty) {
        final parsedIdx = int.tryParse(q.correctChoice);
        if (parsedIdx != null && parsedIdx >= 0 && parsedIdx < q.choices.length) {
          final sIdx = int.tryParse(ans);
          if (sIdx == parsedIdx || ans == q.choices[parsedIdx]) {
            correctCount++;
            continue;
          }
        }
        if (ans == q.correctChoice) correctCount++;
      }
    }

    final elapsedSeconds = stopwatch.elapsed.inSeconds;

    // Save practice result locally
    await _db.saveChallengePracticeResult(
      challengeId: challengeId,
      score: correctCount,
      totalQuestions: totalQuestions,
      userAnswers: userAnswers,
      timeSpentSeconds: elapsedSeconds,
    );

    if (questions.isNotEmpty) {
      final isDown = await _db.isChallengeDownloaded(challengeId);
      if (!isDown) {
        await _db.insertDownloadedChallengeBundle({
          'id': challengeId,
          'challenge_id': challengeId,
          'title': title,
          'questions': questions.map((q) => q.toJson()).toList(),
        });
      }
    }

    // Notify controllers of completion and downloaded availability
    if (Get.isRegistered<ChallengeHomeController>()) {
      final hCtrl = ChallengeHomeController.instance;
      hCtrl.markAttemptedOrPracticed(challengeId);
      hCtrl.downloadedIds.add(challengeId);
      hCtrl.refreshAttemptStates();
    }
    if (Get.isRegistered<ChallengeArchiveController>()) {
      final aCtrl = ChallengeArchiveController.instance;
      aCtrl.markAttemptedOrPracticed(challengeId);
      aCtrl.downloadedIds.add(challengeId);
      aCtrl.refreshAttemptStates();
    }

    // Navigate to Review Screen
    Get.off(
      () => ChallengeReviewScreen(
        challengeId: challengeId,
        title: title,
        questions: questions,
        userAnswers: userAnswers,
        score: correctCount,
        timeSpentSeconds: elapsedSeconds,
      ),
    );
  }
}
