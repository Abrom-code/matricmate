import 'dart:async';

import 'package:get/get.dart';
import 'package:matricmate/bindings/exam/entrance_exams_binding.dart';
import 'package:matricmate/bindings/exam/grade_test_binding.dart';
import 'package:matricmate/bindings/exam/test_binding.dart';
import 'package:matricmate/features/exam/controllers/chapter_test_controller.dart';
import 'package:matricmate/features/exam/controllers/entrance_exams_controller.dart';
import 'package:matricmate/features/exam/controllers/exam_selection_controller.dart';
import 'package:matricmate/features/exam/controllers/grade_test_controller.dart';
import 'package:matricmate/features/exam/models/test_model.dart';
import 'package:matricmate/features/exam/screens/entrance/entrance_exams.dart';
import 'package:matricmate/features/exam/screens/ready/ready.dart';
import 'package:matricmate/features/exam/screens/tests_list/chapter_test.dart';
import 'package:matricmate/features/exam/screens/tests_list/grade_tests.dart';

/// Handles "tap a push notification (or in-app notification row) → land on
/// the exact test's ReadyDialog", the same way tapping a TestTile does.
///
/// Because opening a test requires the right list controller
/// (ChapterTestController / GradeTestController / ExamsController) to
/// finish loading first, this navigates to the matching list screen with
/// the right arguments, waits for that controller's isLoading to flip to
/// false, finds the test by id, then opens ReadyDialog exactly as the
/// tiles in exam_list.dart / chapter_test.dart / grade_test.dart do.
///
/// Expected payload keys (set by the Supabase Edge Function / trigger):
///   type        : 'chapter' | 'grade' | 'entrance' | 'model'
///   test_id     : the test's numeric id
///   subject_id  : parent subject id
///   subject     : subject display name
///   grade       : (chapter/grade only)
///   chapter_id  : (chapter only)
///   chapter     : (chapter only) chapter title
///   chapter_number : (chapter only)
class NotificationTestOpener {
  NotificationTestOpener._();

  static Future<void> open(Map<String, dynamic> data) async {
    final testType = data['test_type'] as String? ?? data['type'] as String?;
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

  /// Controllers registered via a screen's `binding:` aren't instantly
  /// available the moment Get.to() returns — poll briefly until Get.find
  /// succeeds (bounded so a broken deep link can't hang forever).
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
