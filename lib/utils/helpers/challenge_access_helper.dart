import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matricmate/features/authentication/models/user_model.dart';
import 'package:matricmate/features/challenges/models/challenge_model.dart';
import 'package:matricmate/routes/app_routes.dart';

/// Central access gatekeeper for challenges.
///
/// - Free challenges (`isPremium == false`) are accessible to all users.
/// - Premium challenges (`isPremium == true`) require an active subscription (`user.isActive`).
class ChallengeAccessHelper {
  const ChallengeAccessHelper._();

  /// Determines whether the [user] has permission to access the given [challenge].
  static bool canAccess({
    required LeaderboardChallengeModel challenge,
    required UserModel user,
  }) {
    if (!challenge.isPremium) return true;
    return user.isActive;
  }

  /// Handles user interaction when tapping a challenge tile/card:
  /// - Invokes [onAccessible] if the user has access.
  /// - Routes to payment verification screen if the user has a pending receipt.
  /// - Navigates directly to [Routes.premium] if the user is inactive.
  static void handleChallengeTap({
    required LeaderboardChallengeModel challenge,
    required UserModel user,
    required VoidCallback onAccessible,
  }) {
    if (canAccess(challenge: challenge, user: user)) {
      onAccessible();
      return;
    }

    if (user.isPending) {
      Get.toNamed(Routes.paymentVerification);
      return;
    }

    Get.toNamed(Routes.premium);
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

  /// Sorts a list of challenges based on user subscription status:
  /// - For inactive or pending users, free challenges (`isPremium == false`) appear first on top.
  /// - For active subscribers (all challenges unlocked), original order is preserved.
  /// - Within the same tier, original relative order is preserved.
  static List<LeaderboardChallengeModel> sortForUser(
    List<LeaderboardChallengeModel> challenges,
    UserModel user,
  ) {
    if (user.isActive || challenges.isEmpty) return challenges;

    final free = <LeaderboardChallengeModel>[];
    final premium = <LeaderboardChallengeModel>[];

    for (final challenge in challenges) {
      if (challenge.isPremium) {
        premium.add(challenge);
      } else {
        free.add(challenge);
      }
    }

    return [...free, ...premium];
  }
}
