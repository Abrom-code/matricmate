import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matricmate/common/widgets/loaders/full_screen_loader.dart';
import 'package:matricmate/features/challenges/controllers/challenge_home_controller.dart';
import 'package:matricmate/features/challenges/models/challenge_model.dart';
import 'package:matricmate/features/notifications/controllers/notifications_controller.dart';
import 'package:matricmate/features/notifications/models/notification_model.dart';
import 'package:matricmate/features/notifications/screens/notification_detail_screen.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/formatter/formatter.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationTile extends StatelessWidget {
  const NotificationTile({
    super.key,
    required this.notification,
    required this.onDismissed,
  });

  final AppNotification notification;

  /// Callback fired on dismissal swipe completion.
  final VoidCallback onDismissed;

  // ── Derived from type + payload ──────────────────────────────────────

  /// Payment sub-status from payload: 'active' | 'rejected' | other.
  String get _paymentStatus => notification.payload['status']?.toString() ?? '';

  bool get _isApproved =>
      notification.type == 'payment' && _paymentStatus == 'active';

  bool get _isRejected =>
      notification.type == 'payment' && _paymentStatus == 'rejected';

  bool get _isChallenge =>
      notification.type == 'challenge' ||
      notification.type == 'challenge_round' ||
      notification.type == 'challenge_reward' ||
      notification.payload.containsKey('challenge_id');

  bool get _isChallengeClosed {
    if (notification.type == 'challenge_reward') return true;
    final status = notification.payload['status']?.toString().toLowerCase();
    return status == 'closed' || status == 'archived';
  }

  Color _accentColor() {
    if (_isApproved) return const Color(0xFF10B981);
    if (_isRejected) return const Color(0xFFEF4444);
    if (notification.type == 'payment') return const Color(0xFFF59E0B);
    if (notification.type == 'new_content') return const Color(0xFF0284C7);
    if (_isChallenge) {
      return _isChallengeClosed
          ? const Color(0xFFD97706) // Standings Trophy Amber
          : const Color(0xFF2563EB); // Challenge Royal Blue
    }
    return AppColors.primary;
  }

  _TypeIconData get _typeIcon {
    if (_isApproved) {
      return const _TypeIconData(
        Icons.verified_rounded,
        Color(0xFF10B981),
      );
    }
    if (_isRejected) {
      return const _TypeIconData(
        Icons.cancel_rounded,
        Color(0xFFEF4444),
      );
    }
    if (_isChallenge) {
      return _TypeIconData(
        _isChallengeClosed
            ? Icons.leaderboard_rounded
            : Icons.emoji_events_rounded,
        _isChallengeClosed
            ? const Color(0xFFD97706)
            : const Color(0xFF2563EB),
      );
    }

    switch (notification.type) {
      case 'payment':
        return const _TypeIconData(
          Icons.account_balance_wallet_rounded,
          Color(0xFFF59E0B),
        );
      case 'new_content':
        return const _TypeIconData(
          Icons.menu_book_rounded,
          Color(0xFF0284C7),
        );
      default:
        return const _TypeIconData(
          Icons.campaign_rounded,
          AppColors.primary,
        );
    }
  }

  String get _categoryLabel {
    if (notification.type == 'payment') return 'PAYMENT';
    if (notification.type == 'new_content') return 'NEW TEST';
    if (_isChallenge) {
      return _isChallengeClosed ? 'STANDINGS' : 'CHALLENGE';
    }
    return 'ANNOUNCEMENT';
  }

  Future<void> _onTap() async {
    unawaited(NotificationsController.instance.markRead(notification.id));

    if (_isChallenge) {
      LeaderboardChallengeModel? matchedChallenge;
      final challengeId = notification.payload['challenge_id']?.toString() ??
          notification.payload['id']?.toString();

      if (challengeId != null && challengeId.isNotEmpty) {
        // 1. Check in-memory controller for 0ms instant match
        if (Get.isRegistered<ChallengeHomeController>()) {
          final ctrl = ChallengeHomeController.instance;
          matchedChallenge = ctrl.completedChallenges.firstWhereOrNull(
            (c) => c.id == challengeId || c.setId == challengeId,
          ) ?? ctrl.availableChallenges.firstWhereOrNull(
            (c) => c.id == challengeId || c.setId == challengeId,
          );
        }

        // 2. If not found in memory, show full-screen loader and fetch
        if (matchedChallenge == null) {
          AppFullScreenLoader.openLoadingDialog('Opening challenge...');
          try {
            final sb = Supabase.instance.client;
            final row = await sb
                .from('leaderboard_challenges')
                .select('*, subjects(name)')
                .eq('id', challengeId)
                .maybeSingle()
                .timeout(const Duration(seconds: 4));
            if (row != null) {
              matchedChallenge = LeaderboardChallengeModel.fromJson(row);
            }
          } catch (_) {
          } finally {
            AppFullScreenLoader.stopLoading();
          }
        }
      }

      Get.to(
        () => NotificationDetailScreen(
          notification: notification,
          initialChallenge: matchedChallenge,
        ),
      );
      return;
    }

    Get.to(() => NotificationDetailScreen(notification: notification));
  }

  @override
  Widget build(BuildContext context) {
    final dark = AppHelperFunctions.isDark(context);
    final iconData = _typeIcon;
    final accent = _accentColor();
    final isUnread = !notification.isRead;

    return Dismissible(
      key: ValueKey(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismissed(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.delete_outline_rounded,
              color: Colors.white,
              size: 20,
            ),
            SizedBox(width: 6),
            Text(
              'Delete',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
      child: GestureDetector(
        onTap: _onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isUnread
                ? (dark
                    ? const Color(0xFF1E232E)
                    : const Color(0xFFF8FAFC))
                : (dark ? AppColors.darkCard : AppColors.white),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isUnread
                  ? accent.withValues(alpha: dark ? 0.40 : 0.28)
                  : (dark ? AppColors.darkBorder : const Color(0xFFE2E8F0)),
              width: isUnread ? 1.4 : 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: dark ? 0.2 : 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ── Type icon squircle ─────────────────────────────────
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: iconData.color.withValues(alpha: dark ? 0.22 : 0.10),
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(
                        color: iconData.color.withValues(alpha: dark ? 0.35 : 0.20),
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Icon(iconData.icon, size: 22, color: iconData.color),
                    ),
                  ),
                  if (isUnread)
                    Positioned(
                      top: -2,
                      right: -2,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: accent,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: dark ? AppColors.darkCard : AppColors.white,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 14),

              // ── Content ───────────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Meta row: Category pill + date + status badge
                    Row(
                      children: [
                        Text(
                          _categoryLabel,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: accent,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '·',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: dark
                                ? AppColors.darkGrey
                                : AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _relativeTime(notification.createdAt),
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                              color: dark
                                  ? AppColors.darkGrey
                                  : AppColors.textSecondary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (_isApproved)
                          _StatusBadge(
                            label: 'Approved',
                            color: const Color(0xFF10B981),
                            dark: dark,
                          )
                        else if (_isRejected)
                          _StatusBadge(
                            label: 'Rejected',
                            color: const Color(0xFFEF4444),
                            dark: dark,
                          ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    // Title
                    Text(
                      notification.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: isUnread ? FontWeight.w800 : FontWeight.w700,
                        fontSize: 14.5,
                        letterSpacing: -0.2,
                        color: dark ? AppColors.white : const Color(0xFF0F172A),
                      ),
                    ),

                    const SizedBox(height: 3),

                    // Body clamped to 2 lines
                    Text(
                      notification.body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.4,
                        color: isUnread
                            ? (dark
                                ? const Color(0xFFCBD5E1)
                                : const Color(0xFF334155))
                            : (dark
                                ? AppColors.darkGrey
                                : AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Trailing chevron
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: dark
                    ? AppColors.darkGrey.withValues(alpha: 0.6)
                    : AppColors.textSecondary.withValues(alpha: 0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Type icon helper ──────────────────────────────────────────────────────────

class _TypeIconData {
  final IconData icon;
  final Color color;
  const _TypeIconData(this.icon, this.color);
}

// ── Small status badge ────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
    required this.label,
    required this.color,
    required this.dark,
  });

  final String label;
  final Color color;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: dark ? 0.22 : 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: dark ? 0.35 : 0.25),
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

// ── Relative time helper ──────────────────────────────────────────────────────

String _relativeTime(DateTime dt) {
  final now = DateTime.now();
  final diff = now.difference(dt);

  if (diff.inSeconds < 60) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays == 1) return 'Yesterday';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return AppFormatter.formatDate(dt.millisecondsSinceEpoch);
}

