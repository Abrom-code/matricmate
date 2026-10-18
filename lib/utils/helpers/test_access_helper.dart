import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matricmate/common/widgets/loaders/full_screen_loader.dart';
import 'package:matricmate/data/repositories/exam/test_repository.dart';
import 'package:matricmate/features/authentication/models/user_model.dart';
import 'package:matricmate/features/exam/models/test_model.dart';
import 'package:matricmate/features/notes/models/note_model.dart';
import 'package:matricmate/features/personalization/controllers/user_controller.dart';
import 'package:matricmate/routes/app_routes.dart';
import 'package:matricmate/utils/helpers/new_tag_helper.dart';
import 'package:matricmate/utils/helpers/toast_helper.dart';

/// Central access gatekeeper for tests across all 4 test types
/// (chapter, grade, entrance, model) and subject notes.
class TestAccessHelper {
  const TestAccessHelper._();

  /// Determines whether the [user] has permission to access the given [test].
  ///
  /// - Free tests (`isPremium == false`) are accessible to all users.
  /// - Premium tests (`isPremium == true`) require an active subscription (`user.isActive`).
  static bool canAccess({
    required TestModel test,
    required UserModel user,
  }) {
    if (Get.isRegistered<UserController>() &&
        Get.find<UserController>().isAdmin.value) {
      return true;
    }
    if (!test.isPremium) return true;
    return user.isActive;
  }

  /// Returns whether the currently logged-in user has premium/active entitlement (or is admin).
  static bool get isCurrentUserPremium {
    if (!Get.isRegistered<UserController>()) return false;
    final userController = Get.find<UserController>();
    if (userController.isAdmin.value) return true;
    return userController.user.value.isActive;
  }

  /// Returns true if a test (Map or TestModel) is free (non-premium).
  static bool isTestFree(dynamic test) {
    if (test == null) return false;
    if (test is TestModel) return !test.isPremium;
    if (test is Map) {
      final raw = test['is_premium'];
      return raw == false || raw == 0 || raw == 'false' || raw == '0';
    }
    return false;
  }

  /// Handles user interaction when tapping a test tile:
  /// - Invokes [onStart] if the user has access and questions are locally available.
  /// - If user has access but questions are missing locally (e.g. newly upgraded user),
  ///   downloads them on demand before invoking [onStart].
  /// - Routes to payment verification screen if the user has a pending receipt.
  /// - Navigates directly to [Routes.premium] if the user is inactive.
  static Future<void> handleTestTap({
    required TestModel test,
    required UserModel user,
    required VoidCallback onStart,
    void Function(bool hasQuestions, int count)? onQuestionsDownloaded,
  }) async {
    NewTagHelper.markTestOpened(test.id);
    if (!canAccess(test: test, user: user)) {
      if (user.isPending) {
        Get.toNamed(Routes.paymentVerification);
        return;
      }
      Get.toNamed(Routes.premium);
      return;
    }

    // Check if questions are already present locally
    final hasQn = await TestRepository().hasQns(test.id);
    if (hasQn) {
      onStart();
      return;
    }

    // Questions not yet downloaded (e.g. newly upgraded user tapping before background sync finishes)
    try {
      AppFullScreenLoader.openLoadingDialog('Loading test questions...');
      final count = await TestRepository().downloadTestQuestions(
        test.id,
        subjectId: test.subjectId,
      );
      AppFullScreenLoader.stopLoading();

      if (count > 0) {
        onQuestionsDownloaded?.call(true, count);
        onStart();
      } else {
        ToastHelper.info('No questions added yet for this exam!');
      }
    } catch (_) {
      AppFullScreenLoader.stopLoading();
      ToastHelper.error('Could not load questions. Check your connection.');
    }
  }

  /// Navigates to [Routes.premium] or redirects to [Routes.paymentVerification]
  /// if the user already has a pending payment.
  static void openPremiumSheet({required UserModel user}) {
    if (user.isPending) {
      Get.toNamed(Routes.paymentVerification);
      return;
    }

    Get.toNamed(Routes.premium);
  }

  /// Sorts a list of tests based on user subscription status:
  /// - For inactive or pending users, free tests (`isPremium == false`) appear first on top.
  /// - For active subscribers (all tests unlocked), original database order is preserved.
  /// - Within the same tier, original relative order is preserved.
  static List<TestModel> sortForUser(List<TestModel> tests, UserModel user) {
    if (user.isActive || tests.isEmpty) return tests;

    final free = <TestModel>[];
    final premium = <TestModel>[];

    for (final test in tests) {
      if (test.isPremium) {
        premium.add(test);
      } else {
        free.add(test);
      }
    }

    return [...free, ...premium];
  }

  /// Sorts a list of notes based on user subscription status:
  /// - For inactive or pending users (free), free notes (`isPremium == false`) appear first on top.
  /// - For active subscribers (premium), original database order is preserved.
  /// - Within the same tier, original relative order is preserved.
  static List<NoteModel> sortNotesForUser(List<NoteModel> notes, UserModel user) {
    if (user.isActive || notes.isEmpty) return notes;

    final free = <NoteModel>[];
    final premium = <NoteModel>[];

    for (final note in notes) {
      if (note.isPremium) {
        premium.add(note);
      } else {
        free.add(note);
      }
    }

    return [...free, ...premium];
  }
}
