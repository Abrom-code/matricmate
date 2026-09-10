import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matricmate/common/widgets/exam/premium_bottom_sheet.dart';
import 'package:matricmate/features/authentication/models/user_model.dart';
import 'package:matricmate/features/exam/models/test_model.dart';
import 'package:matricmate/routes/app_routes.dart';

/// Central access gatekeeper for tests across all 4 test types
/// (chapter, grade, entrance, model).
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
    if (!test.isPremium) return true;
    return user.isActive;
  }

  /// Handles user interaction when tapping a test tile:
  /// - Invokes [onStart] if the user has access.
  /// - Routes to payment verification screen if the user has a pending receipt.
  /// - Opens the upgrade [PremiumBottomSheet] if the user is inactive.
  static void handleTestTap({
    required TestModel test,
    required UserModel user,
    required VoidCallback onStart,
  }) {
    if (canAccess(test: test, user: user)) {
      onStart();
      return;
    }

    if (user.isPending) {
      Get.toNamed(Routes.paymentVerification);
      return;
    }

    Get.bottomSheet(
      const PremiumBottomSheet(),
      isScrollControlled: true,
    );
  }
}
