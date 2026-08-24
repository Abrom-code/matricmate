import 'dart:async';

import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:matricmate/bindings/exam/entrance_exams_binding.dart';
import 'package:matricmate/bindings/exam/grade_test_binding.dart';
import 'package:matricmate/bindings/exam/test_binding.dart';
import 'package:matricmate/controllers/navigation_controller.dart';
import 'package:matricmate/data/repositories/challenge/challenge_repository.dart';
import 'package:matricmate/features/challenges/models/challenge_attempt_model.dart';
import 'package:matricmate/features/challenges/models/challenge_model.dart';
import 'package:matricmate/features/challenges/screens/challenge_attempt_screen.dart';
import 'package:matricmate/features/challenges/screens/challenge_practice_screen.dart';
import 'package:matricmate/features/exam/controllers/chapter_test_controller.dart';
import 'package:matricmate/features/exam/controllers/entrance_exams_controller.dart';
import 'package:matricmate/features/exam/controllers/exam_selection_controller.dart';
import 'package:matricmate/features/exam/controllers/grade_test_controller.dart';
import 'package:matricmate/features/exam/models/test_model.dart';
import 'package:matricmate/features/exam/screens/entrance/entrance_exams.dart';
import 'package:matricmate/features/exam/screens/ready/ready.dart';
import 'package:matricmate/features/exam/screens/tests_list/chapter_test.dart';
import 'package:matricmate/features/exam/screens/tests_list/grade_tests.dart';
import 'package:matricmate/features/personalization/controllers/user_controller.dart';
import 'package:matricmate/utils/helpers/toast_helper.dart';

/// Handles deep-linking from notifications directly to the target test or challenge.
class NotificationTestOpener {
  NotificationTestOpener._();

  static Future<void> open(Map<String, dynamic> data) async {
    final testType = data['test_type'] as String? ?? data['type'] as String?;
    
    // Handle challenge deep links
    if (data.containsKey('challenge_id') ||
        testType == 'challenge' ||
        testType == 'challenge_round' ||
        testType == 'challenge_reward') {
      await _openChallenge(data);
      return;
    }

    final testId = int.tryParse('${data['test_id']}');
    if (testType == null || testId == null) return;

    switch (testType) {
      case 'chapter':
        await _openChapterTest(data, testId);
        break;
      case 'grade':
        await _openGradeTest(data, testId);
        break;
      case 'entrance':
      case 'model':
        await _openEntranceTest(data, testId, testType);
        break;
      default:
        // Unknown/announcement payload — nothing to navigate to.
        break;
    }
  }

  // ── Challenge deep link ───────────────────────────────────────────────

  static Future<void> _openChallenge(Map<String, dynamic> data) async {
    final challengeId =
        data['challenge_id']?.toString() ?? data['id']?.toString();
    if (challengeId == null || challengeId.isEmpty) {
      NavigationController.navigateToTab(1);
      return;
    }

    try {
      final sb = Supabase.instance.client;
      final row = await sb
          .from('leaderboard_challenges')
          .select('*, subjects(name)')
          .eq('id', challengeId)
          .maybeSingle();

      if (row == null) {
        NavigationController.navigateToTab(1);
        return;
      }

      final challenge = LeaderboardChallengeModel.fromJson(row);
      final user = UserController.instance.user.value;
      final isPremium = user.isActive;
      final userStream = user.stream.toLowerCase().trim();

      // 1. Premium Gate (Redirects to challenge page where locked challenges are displayed with navbar)
      if (!isPremium) {
        NavigationController.navigateToTab(1);
        return;
      }

      // 2. Stream Audience Gate
      final aud = challenge.audience.toLowerCase().trim();
      if (aud != 'both' && userStream.isNotEmpty && aud != userStream) {
        NavigationController.navigateToTab(1);
        ToastHelper.warning(
          'This challenge is open to ${challenge.audience.toUpperCase()} stream students.',
        );
        return;
      }

      // 3. Check if user already submitted an attempt
      if (user.id.isNotEmpty) {
        final repo = ChallengeRepository();
        final attemptData = await repo.fetchUserAttempt(
          challengeId: challenge.id,
          userId: user.id,
        );
        if (attemptData != null &&
            attemptData['attempt'] is ChallengeAttemptModel) {
          final attempt = attemptData['attempt'] as ChallengeAttemptModel;
          if (attempt.isSubmitted) {
            NavigationController.navigateToTab(1);
            ToastHelper.info(
              'You have already submitted your attempt for this challenge.',
            );
            return;
          }
        }
      }

      // 4. Status & Timing Checks
      if (challenge.isLive) {
        Get.to(
          () => ChallengeAttemptScreen(
            challengeId: challenge.id,
            title: challenge.title,
            audience: challenge.audience,
          ),
        );
      } else if (challenge.isScheduled) {
        NavigationController.navigateToTab(1);
        if (challenge.startsAt != null) {
          final diff = challenge.startsAt!.difference(DateTime.now());
          if (!diff.isNegative) {
            final hours = diff.inHours;
            final mins = diff.inMinutes % 60;
            final timeStr = hours > 0 ? '${hours}h ${mins}m' : '${mins}m';
            ToastHelper.info('This challenge opens in $timeStr. Get ready!');
          } else {
            ToastHelper.info('This challenge will open shortly. Get ready!');
          }
        } else {
          ToastHelper.info('This challenge has not started yet.');
        }
      } else if (challenge.isClosed || challenge.isArchived) {
        Get.to(
          () => ChallengePracticeScreen(
            challengeId: challenge.id,
            title: challenge.title,
          ),
        );
        ToastHelper.info(
          'This challenge round has ended. You can practice it now.',
        );
      } else {
        NavigationController.navigateToTab(1);
      }
    } catch (_) {
      NavigationController.navigateToTab(1);
    }
  }

  // ── Chapter test ──────────────────────────────────────────────────────

  static Future<void> _openChapterTest(
    Map<String, dynamic> data,
    int testId,
  ) async {
    Get.to(
      () => const ChapterTestScreen(),
      binding: TestBinding(),
      arguments: {
        'subject': data['subject'] ?? '',
        'subject_id': int.tryParse('${data['subject_id']}') ?? 0,
        'grade': int.tryParse('${data['grade']}') ?? 9,
        'chapter': data['chapter'] ?? '',
        'chapter_id': int.tryParse('${data['chapter_id']}') ?? 0,
        'chapter_number': int.tryParse('${data['chapter_number']}') ?? 0,
      },
    );

    final ctrl = await _waitForController<ChapterTestController>(
      () => ChapterTestController.instance,
    );
    if (ctrl == null) return;
    await _waitUntilLoaded(ctrl.isLoading);

    final test = ctrl.chapterTest.firstWhereOrNull((t) => t.id == testId);
    if (test == null) return;

    _openReadyDialog(
      test: test,
      id: 1,
      draft: ctrl.isInProgress(testId) ? ctrl.testResults[testId] : null,
      qnCount: ctrl.testQuestionCounts[testId] ?? test.questionCount,
    );
  }

  // ── Grade test ────────────────────────────────────────────────────────

  static Future<void> _openGradeTest(
    Map<String, dynamic> data,
    int testId,
  ) async {
    Get.to(
      () => const GradeTestsScreen(),
      binding: GradeTestBinding(),
      arguments: {
        'subject': data['subject'] ?? '',
        'subject_id': int.tryParse('${data['subject_id']}') ?? 0,
        'grade': int.tryParse('${data['grade']}') ?? 9,
      },
    );

    final ctrl = await _waitForController<GradeTestController>(
      () => GradeTestController.instance,
    );
    if (ctrl == null) return;
    await _waitUntilLoaded(ctrl.isLoading);

    final test = ctrl.chapterTests.firstWhereOrNull((t) => t.id == testId);
    if (test == null) return;

    _openReadyDialog(
      test: test,
      id: 0,
      draft: ctrl.isInProgress(testId) ? ctrl.testResults[testId] : null,
      qnCount: ctrl.testQuestionCounts[testId] ?? test.questionCount,
    );
  }

  // ── Entrance / model test ─────────────────────────────────────────────

  static Future<void> _openEntranceTest(
    Map<String, dynamic> data,
    int testId,
    String testType,
  ) async {
    Get.to(
      () => const EntranceExamsScreen(),
      binding: EntranceExamsBinding(),
      arguments: {
        'subject': data['subject'] ?? '',
        'subject_id': int.tryParse('${data['subject_id']}') ?? 0,
      },
    );

    final ctrl = await _waitForController<EntranceExamsController>(
      () => EntranceExamsController.instance,
    );
    if (ctrl == null) return;
    await _waitUntilLoaded(ctrl.isLoading);

    // Switch to the correct tab so the user visually lands where the test lives.
    if (Get.isRegistered<ExamSelectionController>()) {
      Get.find<ExamSelectionController>().tabController.index =
          testType == 'model' ? 1 : 0;
    }

    final list = testType == 'model' ? ctrl.modelTests : ctrl.entranceTests;
    final test = list.firstWhereOrNull((t) => t.id == testId);
    if (test == null) return;

    _openReadyDialog(
      test: test,
      id: 2,
      draft: ctrl.isInProgress(testId) ? ctrl.testResults[testId] : null,
      qnCount: ctrl.testQuestionCounts[testId] ?? test.questionCount,
      examTitle: test.title,
    );
  }

  // ── Shared helpers ────────────────────────────────────────────────────

  static void _openReadyDialog({
    required TestModel test,
    required int id,
    required dynamic draft,
    required int qnCount,
    String? examTitle,
  }) {
    Get.dialog(
      ReadyDialog(
        qnCount: qnCount,
        time: test.time,
        testId: test.id,
        id: id,
        draft: draft,
        examTitle: examTitle,
      ),
    );
  }

  /// Bounded poll for lazy controller registration after navigation.
  static Future<T?> _waitForController<T>(T Function() find) async {
    for (int i = 0; i < 20; i++) {
      try {
        return find();
      } catch (_) {
        await Future.delayed(const Duration(milliseconds: 50));
      }
    }
    return null;
  }

  static Future<void> _waitUntilLoaded(RxBool isLoading) async {
    if (!isLoading.value) return;
    final completer = Completer<void>();
    late Worker worker;
    worker = ever<bool>(isLoading, (loading) {
      if (!loading) {
        worker.dispose();
        if (!completer.isCompleted) completer.complete();
      }
    });
    await completer.future.timeout(
      const Duration(seconds: 8),
      onTimeout: () => worker.dispose(),
    );
  }
}
