import 'dart:async';
import 'package:get/get.dart';
import 'package:matricmate/data/repositories/challenge/challenge_repository.dart';
import 'package:matricmate/features/challenges/models/challenge_question_model.dart';
import 'package:matricmate/features/challenges/screens/leaderboard_screen.dart';
import 'package:matricmate/features/personalization/controllers/user_controller.dart';
import 'package:matricmate/utils/exceptions/exception_handler.dart';
import 'package:matricmate/utils/helpers/toast_helper.dart';

class ChallengeAttemptController extends GetxController {
  ChallengeAttemptController({required this.challengeId, required this.title});

  final String challengeId;
  final String title;

  final _repo = ChallengeRepository();

  final isLoading = true.obs;
  final isSubmitting = false.obs;
  final questions = <ChallengeQuestionModel>[].obs;
  final currentIndex = 0.obs;

  // Selected answers: { question_id: selected_choice_text }
  final userAnswers = <String, String>{}.obs;

  String? attemptId;
  int durationSeconds = 3600;
  DateTime? startedAt;
  DateTime? endsAt;

  final remainingSeconds = 0.obs;
  Timer? _timer;
  int _timeSpentSeconds = 0;

  int get totalQuestions => questions.length;
  int get answeredCount => userAnswers.length;
  double get progress => totalQuestions > 0 ? answeredCount / totalQuestions : 0.0;

  String get formattedRemainingTime {
    final secs = remainingSeconds.value;
    final mins = secs ~/ 60;
    final s = secs % 60;
    return '${mins.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  void onInit() {
    super.onInit();
    startChallenge();
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }

  Future<void> startChallenge() async {
    isLoading.value = true;
    try {
      final userId = UserController.instance.user.value.id;
      final data = await _repo.startAttempt(challengeId: challengeId, userId: userId);

      attemptId = data['attempt_id'];
      durationSeconds = data['duration_seconds'] ?? 3600;
      startedAt = data['started_at'];
      endsAt = data['ends_at'];
      questions.value = data['questions'] ?? [];

      // Calculate initial remaining seconds
      final elapsed = startedAt != null ? DateTime.now().difference(startedAt!).inSeconds : 0;
      final allowed = durationSeconds - elapsed;
      remainingSeconds.value = allowed > 0 ? allowed : 0;

      _startTimer();
    } catch (e) {
      AppExceptionHandler.handleResponse(e);
      Get.back();
    } finally {
      isLoading.value = false;
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _timeSpentSeconds++;
      if (remainingSeconds.value > 0) {
        remainingSeconds.value--;
      } else {
        timer.cancel();
        _onTimeExpired();
      }
    });
  }

  void _onTimeExpired() {
    ToastHelper.warning('Time is up! Submitting your attempt...');
    submitAttempt(isAutoExpire: true);
  }

  void selectChoice(String questionId, String choice) {
    if (userAnswers[questionId] == choice) return;

    userAnswers[questionId] = choice;

    // Send answer asynchronously to server
    if (attemptId != null) {
      _repo
          .submitAnswer(
            attemptId: attemptId!,
            questionId: questionId,
            selectedChoice: choice,
          )
          .catchError((_) {});
    }
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

  Future<void> submitAttempt({bool isAutoExpire = false}) async {
    if (isSubmitting.value || attemptId == null) return;

    isSubmitting.value = true;
    _timer?.cancel();

    try {
      final res = await _repo.submitAttempt(
        attemptId: attemptId!,
        totalTimeSeconds: _timeSpentSeconds,
      );

      final score = (res['score'] as num?)?.toInt() ?? 0;

      // Show completion feedback and transition to leaderboard
      Get.off(
        () => LeaderboardScreen(
          challengeId: challengeId,
          challengeTitle: title,
          userScore: score,
          userTimeSeconds: _timeSpentSeconds,
        ),
      );
    } catch (e) {
      AppExceptionHandler.handleResponse(e);
    } finally {
      isSubmitting.value = false;
    }
  }
}
