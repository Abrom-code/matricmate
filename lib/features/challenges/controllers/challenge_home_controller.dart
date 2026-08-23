import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matricmate/common/widgets/exam/premium_bottom_sheet.dart';
import 'package:matricmate/data/repositories/challenge/challenge_repository.dart';
import 'package:matricmate/features/challenges/models/challenge_model.dart';
import 'package:matricmate/features/challenges/screens/challenge_attempt_screen.dart';
import 'package:matricmate/features/challenges/screens/leaderboard_screen.dart';
import 'package:matricmate/features/personalization/controllers/user_controller.dart';
import 'package:matricmate/utils/exceptions/exception_handler.dart';
import 'package:matricmate/utils/helpers/toast_helper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChallengeHomeController extends GetxController {
  static ChallengeHomeController get instance => Get.find();

  final _repo = ChallengeRepository();
  final _sb = Supabase.instance.client;

  final isLoading = false.obs;
  final challenges = <LeaderboardChallengeModel>[].obs;
  final now = DateTime.now().obs;

  Timer? _countdownTimer;
  RealtimeChannel? _realtimeChannel;

  bool get isPremium => UserController.instance.user.value.isActive;
  String get userStream => UserController.instance.user.value.stream;

  @override
  void onInit() {
    super.onInit();
    loadChallenges();
    _startTimer();
    _startRealtime();

    // Listen to user status changes
    ever(UserController.instance.user, (_) => update());
  }

  @override
  void onClose() {
    _countdownTimer?.cancel();
    if (_realtimeChannel != null) {
      _sb.removeChannel(_realtimeChannel!);
    }
    super.onClose();
  }

  void _startTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      now.value = DateTime.now();
    });
  }

  void _startRealtime() {
    _realtimeChannel = _sb
        .channel('challenge_updates')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'leaderboard_challenges',
          callback: (payload) {
            debugPrint('[Realtime] Challenge changed: ${payload.eventType}');
            loadChallenges(showLoading: false);
          },
        )
        .subscribe();
  }

  Future<void> loadChallenges({bool showLoading = true}) async {
    if (showLoading) isLoading.value = true;
    try {
      final list = await _repo.fetchVisibleChallenges(stream: userStream);
      challenges.value = list;
    } catch (e) {
      if (showLoading) AppExceptionHandler.handleResponse(e);
    } finally {
      if (showLoading) isLoading.value = false;
    }
  }

  String formatCountdown(DateTime target) {
    final current = now.value;
    final diff = target.difference(current);
    if (diff.isNegative) return 'Starting now...';

    final hours = diff.inHours;
    final minutes = diff.inMinutes % 60;
    final seconds = diff.inSeconds % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  void onChallengeTapped(LeaderboardChallengeModel challenge) {
    // 1. Check premium requirement
    if (!isPremium) {
      Get.bottomSheet(
        const PremiumBottomSheet(),
        isScrollControlled: true,
      );
      return;
    }

    // 2. State-specific routing
    if (challenge.isLive) {
      Get.to(
        () => ChallengeAttemptScreen(challengeId: challenge.id, title: challenge.title),
      );
    } else if (challenge.isScheduled) {
      if (challenge.startsAt != null) {
        ToastHelper.info(
          'Opens in ${formatCountdown(challenge.startsAt!)}. Get ready!',
        );
      } else {
        ToastHelper.info('This challenge has not started yet.');
      }
    } else if (challenge.isClosed || challenge.isArchived) {
      Get.to(
        () => LeaderboardScreen(
          challengeId: challenge.id,
          challengeTitle: challenge.title,
          audience: challenge.audience,
        ),
      );
    }
  }
}
