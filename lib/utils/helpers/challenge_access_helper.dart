import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matricmate/features/authentication/models/user_model.dart';
import 'package:matricmate/features/challenges/models/challenge_model.dart';
import 'package:matricmate/features/challenges/screens/leaderboard_screen.dart';
import 'package:matricmate/features/personalization/controllers/user_controller.dart';
import 'package:matricmate/routes/app_routes.dart';

/// Central access gatekeeper for challenges.
///
/// - Free challenges (`isPremium == false`) are accessible to all users.
/// - Premium challenges (`isPremium == true`) require an active subscription (`user.isActive`).
class ChallengeAccessHelper {
  const ChallengeAccessHelper._();

  /// Determines whether the current user is on the free tier (inactive and not admin).
  static bool get isFreeUser {
    if (Get.isRegistered<UserController>()) {
      final user = UserController.instance.user.value;
      final isAdmin = UserController.instance.isAdmin.value;
      return !user.isActive && !isAdmin;
    }
    return false;
  }

  /// Determines whether the [user] has permission to access the given [challenge].
  static bool canAccess({
    required LeaderboardChallengeModel challenge,
    required UserModel user,
  }) {
    if (Get.isRegistered<UserController>() &&
        Get.find<UserController>().isAdmin.value) {
      return true;
    }
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

  /// Opens the [LeaderboardScreen] if the user is a premium subscriber or admin.
  /// If the user is on the free tier, redirects directly to the premium screen
  /// (or payment verification if payment is pending).
  static void openLeaderboard({
    String? challengeId,
    String? challengeTitle,
    String? audience,
    int? userScore,
    int? userTimeSeconds,
    bool replace = false,
  }) {
    if (isFreeUser) {
      openPremiumSheet(replace: replace);
      return;
    }

    if (replace) {
      Get.off(
        () => LeaderboardScreen(
          challengeId: challengeId,
          challengeTitle: challengeTitle,
          audience: audience,
          userScore: userScore,
          userTimeSeconds: userTimeSeconds,
        ),
      );
    } else {
      Get.to(
        () => LeaderboardScreen(
          challengeId: challengeId,
          challengeTitle: challengeTitle,
          audience: audience,
          userScore: userScore,
          userTimeSeconds: userTimeSeconds,
        ),
      );
    }
  }

  /// Navigates to [Routes.premium] or redirects to [Routes.paymentVerification]
  /// if the user already has a pending payment.
  static void openPremiumSheet({UserModel? user, bool replace = false}) {
    final effectiveUser = user ??
        (Get.isRegistered<UserController>()
            ? UserController.instance.user.value
            : UserModel.empty());
    final targetRoute = effectiveUser.isPending
        ? Routes.paymentVerification
        : Routes.premium;

    if (replace) {
      Get.offNamed(targetRoute);
    } else {
      Get.toNamed(targetRoute);
    }
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
