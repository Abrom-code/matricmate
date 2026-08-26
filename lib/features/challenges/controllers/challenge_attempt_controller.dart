import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:matricmate/common/widgets/loaders/full_screen_loader.dart';
import 'package:matricmate/controllers/navigation_controller.dart';
import 'package:matricmate/data/database/database_service.dart';
import 'package:matricmate/features/challenges/controllers/challenge_archive_controller.dart';
import 'package:matricmate/features/challenges/controllers/challenge_home_controller.dart';
import 'package:matricmate/data/repositories/challenge/challenge_repository.dart';
import 'package:matricmate/features/challenges/models/challenge_question_model.dart';
import 'package:matricmate/features/challenges/screens/challenge_practice_screen.dart';
import 'package:matricmate/features/challenges/screens/challenge_review_screen.dart';
import 'package:matricmate/features/personalization/controllers/user_controller.dart';
import 'package:matricmate/utils/exceptions/exception_handler.dart';
import 'package:matricmate/utils/helpers/toast_helper.dart';

class ChallengeAttemptController extends GetxController
    with WidgetsBindingObserver {
  ChallengeAttemptController({
    required this.challengeId,
    required this.title,
    this.audience,
    this.endsAt,
    int? durationMinutes,
  }) {
    if (durationMinutes != null && durationMinutes > 0) {
      durationSeconds = durationMinutes * 60;
    }
    startedAt = DateTime.now();
    _syncTimerWithWallClock();
  }

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
  double get progress =>
      totalQuestions > 0 ? answeredCount / totalQuestions : 0.0;

  String get formattedRemainingTime {
    final secs = remainingSeconds.value;
    final mins = secs ~/ 60;
    final s = secs % 60;
    return '${mins.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    startChallenge();
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _syncTimerWithWallClock();
    }
  }

  Future<void> startChallenge() async {
    isLoading.value = true;
    try {
      final userId = UserController.instance.user.value.id;
      final data = await _repo.startAttempt(
        challengeId: challengeId,
        userId: userId,
      );

      attemptId = data['attempt_id'];
      durationSeconds = data['duration_seconds'] ?? 3600;
      startedAt = data['started_at'];
      endsAt = data['ends_at'];
      questions.value = data['questions'] ?? [];

      if (Get.isRegistered<ChallengeHomeController>()) {
        ChallengeHomeController.instance.markInProgress(challengeId);
      }
      if (Get.isRegistered<ChallengeArchiveController>()) {
        ChallengeArchiveController.instance.markInProgress(challengeId);
      }

      // Restore existing answers if resuming an ongoing attempt
      try {
        final existing = await _repo.fetchUserAttempt(
          challengeId: challengeId,
          userId: userId,
        );
        if (existing != null && existing['user_answers'] is Map) {
          final map = existing['user_answers'] as Map;
          for (final e in map.entries) {
            if (e.key != null && e.value != null) {
              userAnswers[e.key.toString()] = e.value.toString();
            }
          }
        }
      } catch (_) {}

      // Restore last question position where user left off
      try {
        final prefs = await SharedPreferences.getInstance();
        final savedIdx = prefs.getInt('last_q_index_$challengeId');
        if (savedIdx != null && savedIdx >= 0 && savedIdx < questions.length) {
          currentIndex.value = savedIdx;
        } else if (userAnswers.isNotEmpty) {
          final firstUnanswered = questions.indexWhere(
            (q) => !userAnswers.containsKey(q.id),
          );
          if (firstUnanswered != -1) {
            currentIndex.value = firstUnanswered;
          } else {
            currentIndex.value = (questions.length - 1).clamp(0, questions.length - 1);
          }
        }
      } catch (_) {}

      _syncTimerWithWallClock();
      _startTimer();
    } catch (e) {
      Get.back();
      final msg = e.toString().toLowerCase();
      if (msg.contains('already_submitted')) {
        ToastHelper.info(
          'You have already submitted your attempt for this challenge.',
        );
        NavigationController.navigateToTab(1);
      } else if (msg.contains('challenge_not_started') ||
          msg.contains('not_open_yet')) {
        ToastHelper.info(
          'This challenge has not started yet. Check the countdown on the Challenges tab.',
        );
        NavigationController.navigateToTab(1);
      } else if (msg.contains('challenge_ended') ||
          msg.contains('challenge_closed') ||
          msg.contains('challenge_not_active')) {
        ToastHelper.info(
          'This challenge round has ended. You can practice it now.',
        );
        Get.to(
          () => ChallengePracticeScreen(challengeId: challengeId, title: title),
        );
      } else if (msg.contains('premium_required')) {
        NavigationController.navigateToTab(1);
      } else if (msg.contains('stream_not_eligible') ||
          msg.contains('audience_mismatch')) {
        ToastHelper.warning('This challenge is not available for your stream.');
        NavigationController.navigateToTab(1);
      } else {
        AppExceptionHandler.handleResponse(e);
      }
    } finally {
      isLoading.value = false;
    }
  }

  void _syncTimerWithWallClock() {
    if (startedAt == null) return;
    final now = DateTime.now();
    final elapsed = now.difference(startedAt!).inSeconds;
    _timeSpentSeconds = elapsed;

    // 1. Standard remaining time based on challenge duration (e.g., 30 mins)
    final allowedByDuration = durationSeconds - elapsed;

    // 2. Hard cutoff: clamp to challenge window closing time (endsAt, e.g., 4:00 PM)
    int allowed = allowedByDuration;
    if (endsAt != null) {
      final secondsUntilClose = endsAt!.difference(now).inSeconds;
      if (secondsUntilClose < allowed) {
        allowed = secondsUntilClose;
      }
    }

    if (allowed <= 0) {
      remainingSeconds.value = 0;
      _timer?.cancel();
      _onTimeExpired();
    } else {
      remainingSeconds.value = allowed;
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _syncTimerWithWallClock();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _syncTimerWithWallClock();
    });
  }

  void _onTimeExpired() {
    if (isSubmitting.value) return;
    if (Get.isDialogOpen ?? false) {
      Get.back();
    }
    if (Get.isBottomSheetOpen ?? false) {
      Get.back();
    }
    ToastHelper.warning('Time is up! Submitting your attempt...');
    submitAttempt(isAutoExpire: true);
  }

  Future<void> _saveLastQuestionIndex(int index) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('last_q_index_$challengeId', index);
    } catch (_) {}
  }

  Future<void> _clearLastQuestionIndex() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('last_q_index_$challengeId');
    } catch (_) {}
  }

  void selectChoice(String questionId, String choice) {
    if (userAnswers[questionId] == choice) return;

    userAnswers[questionId] = choice;
    _saveLastQuestionIndex(currentIndex.value);

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
      _saveLastQuestionIndex(currentIndex.value);
    }
  }

  void prevQuestion() {
    if (currentIndex.value > 0) {
      currentIndex.value--;
      _saveLastQuestionIndex(currentIndex.value);
    }
  }

  void goToQuestion(int index) {
    if (index >= 0 && index < totalQuestions) {
      currentIndex.value = index;
      _saveLastQuestionIndex(index);
    }
  }

  Future<void> submitAttempt({bool isAutoExpire = false}) async {
    if (isSubmitting.value || attemptId == null) return;

    isSubmitting.value = true;
    _timer?.cancel();
    _clearLastQuestionIndex();

    AppFullScreenLoader.openLoadingDialog(
      isAutoExpire
          ? 'Time is up! Submitting attempt...'
          : 'Submitting challenge attempt...',
    );

    try {
      // 1. Batch sync all local answers to guarantee 100% data integrity even after network glitches
      await _repo.batchSubmitAnswers(
        attemptId: attemptId!,
        answers: userAnswers,
      );

      // 2. Finalize submission and get scored results
      final res = await _repo.submitAttempt(
        attemptId: attemptId!,
        totalTimeSeconds: _timeSpentSeconds,
      );

      final score = (res['score'] as num?)?.toInt() ?? 0;
      final rawQuestions = res['questions'];
      List<ChallengeQuestionModel> reviewQuestions = [];
      if (rawQuestions is List && rawQuestions.isNotEmpty) {
        reviewQuestions = rawQuestions
            .map(
              (q) => ChallengeQuestionModel.fromJson(q as Map<String, dynamic>),
            )
            .toList();
      } else {
        try {
          reviewQuestions = await _repo.fetchQuestionsForReview(challengeId);
        } catch (_) {
          reviewQuestions = questions.toList();
        }
      }

      // 3. Auto-cache attempt results and questions locally to SQLite for instant offline review
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
              'id': challengeId,
              'challenge_id': challengeId,
              'title': title,
              'audience': audience ?? 'both',
              'questions': reviewQuestions.map((q) => q.toJson()).toList(),
            });
          }
        }

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
      } catch (_) {}

      AppFullScreenLoader.stopLoading();

      // 4. Show completion feedback and transition to full review screen
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
      AppFullScreenLoader.stopLoading();
      AppExceptionHandler.handleResponse(e);
    } finally {
      isSubmitting.value = false;
    }
  }
}
