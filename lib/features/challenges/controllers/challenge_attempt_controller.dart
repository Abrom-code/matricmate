import 'package:matricmate/common/widgets/exam/premium_bottom_sheet.dart';
import 'package:matricmate/data/database/database_service.dart';
import 'package:matricmate/features/challenges/controllers/challenge_home_controller.dart';
import 'package:matricmate/features/challenges/controllers/challenge_archive_controller.dart';
import 'dart:async';
import 'package:get/get.dart';
import 'package:matricmate/data/repositories/challenge/challenge_repository.dart';
import 'package:matricmate/features/challenges/models/challenge_question_model.dart';
import 'package:matricmate/features/challenges/screens/challenge_practice_screen.dart';
import 'package:matricmate/features/challenges/screens/challenge_review_screen.dart';
import 'package:matricmate/features/personalization/controllers/user_controller.dart';
import 'package:matricmate/routes/app_routes.dart';
import 'package:matricmate/utils/exceptions/exception_handler.dart';
import 'package:matricmate/utils/helpers/toast_helper.dart';

class ChallengeAttemptController extends GetxController {
  ChallengeAttemptController({
    required this.challengeId,
    required this.title,
    this.audience,
  });

  final String challengeId;
  final String title;
  final String? audience;

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
      Get.back();
      final msg = e.toString().toLowerCase();
      if (msg.contains('already_submitted')) {
        ToastHelper.info('You have already submitted your attempt for this challenge.');
        Get.toNamed(Routes.challengeHome);
      } else if (msg.contains('challenge_not_started') || msg.contains('not_open_yet')) {
        ToastHelper.info('This challenge has not started yet. Check the countdown on the Challenges tab.');
        Get.toNamed(Routes.challengeHome);
      } else if (msg.contains('challenge_ended') ||
          msg.contains('challenge_closed') ||
          msg.contains('challenge_not_active')) {
        ToastHelper.info('This challenge round has ended. You can practice it now.');
        Get.to(() => ChallengePracticeScreen(challengeId: challengeId, title: title));
      } else if (msg.contains('premium_required')) {
        Get.toNamed(Routes.challengeHome);
        Get.bottomSheet(const PremiumBottomSheet(), isScrollControlled: true);
      } else if (msg.contains('stream_not_eligible') || msg.contains('audience_mismatch')) {
        ToastHelper.warning('This challenge is not available for your stream.');
        Get.toNamed(Routes.challengeHome);
      } else {
        AppExceptionHandler.handleResponse(e);
      }
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
      final rawQuestions = res['questions'];
      List<ChallengeQuestionModel> reviewQuestions = [];
      if (rawQuestions is List && rawQuestions.isNotEmpty) {
        reviewQuestions = rawQuestions
            .map((q) => ChallengeQuestionModel.fromJson(q as Map<String, dynamic>))
            .toList();
      } else {
        try {
          reviewQuestions = await _repo.fetchQuestionsForReview(challengeId);
        } catch (_) {
          reviewQuestions = questions.toList();
        }
      }

      // Save to local DB so it's stored and marked as Done locally
      try {
        final db = DatabaseService.instance;
        await db.saveChallengePracticeResult(
          challengeId: challengeId,
          score: score,
          totalQuestions: reviewQuestions.length,
          userAnswers: Map<String, String>.from(userAnswers),
          timeSpentSeconds: _timeSpentSeconds,
        );

        if (reviewQuestions.isNotEmpty) {
          final isDown = await db.isChallengeDownloaded(challengeId);
          if (!isDown) {
            await db.insertDownloadedChallengeBundle({
              'challenge_id': challengeId,
              'title': title,
              'audience': audience ?? 'both',
              'questions': reviewQuestions.map((q) => q.toJson()).toList(),
            });
          }
        }

        if (Get.isRegistered<ChallengeHomeController>()) {
          ChallengeHomeController.instance.markAttemptedOrPracticed(challengeId);
        }
        if (Get.isRegistered<ChallengeArchiveController>()) {
          ChallengeArchiveController.instance.markAttemptedOrPracticed(challengeId);
        }
      } catch (_) {}

      // Show completion feedback and transition to full review screen
      Get.off(
        () => ChallengeReviewScreen(
          title: title,
          questions: reviewQuestions,
          userAnswers: Map<String, String>.from(userAnswers),
          score: score,
          timeSpentSeconds: _timeSpentSeconds,
          challengeId: challengeId,
          audience: audience,
        ),
      );
    } catch (e) {
      AppExceptionHandler.handleResponse(e);
    } finally {
      isSubmitting.value = false;
    }
  }
}
