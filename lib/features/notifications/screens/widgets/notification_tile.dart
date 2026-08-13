import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matricmate/features/notifications/controllers/notifications_controller.dart';
import 'package:matricmate/features/notifications/models/notification_model.dart';
import 'package:matricmate/features/notifications/services/notification_navigator.dart';
import 'package:matricmate/routes/app_routes.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/formatter/formatter.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

class NotificationTile extends StatelessWidget {
  const NotificationTile({
    super.key,
    required this.notification,
    required this.onDismissed,
  });

  final AppNotification notification;

  /// Called after the swipe animation completes. The parent screen
  /// should call `ctrl.deleteOne(id)` and show an undo SnackBar.
  final VoidCallback onDismissed;

  // ── Derived from type + payload ──────────────────────────────────────

  /// Payment sub-status from payload: 'active' | 'rejected' | other.
  String get _paymentStatus =>
      notification.payload['status']?.toString() ?? '';

  bool get _isApproved =>
      notification.type == 'payment' && _paymentStatus == 'active';

  bool get _isRejected =>
      notification.type == 'payment' && _paymentStatus == 'rejected';

  Color _borderColor(bool dark) {
    if (notification.isRead) return Colors.transparent;
    if (_isApproved) return Colors.green.withValues(alpha: 0.5);
    if (_isRejected) return Colors.red.withValues(alpha: 0.5);
    return AppColors.primary.withValues(alpha: 0.4);
  }

  // ── Type icon ────────────────────────────────────────────────────────

  _TypeIconData get _typeIcon {
    if (_isApproved) {
      return _TypeIconData(Icons.check_circle_rounded, Colors.green.shade600);
    }
    if (_isRejected) {
      return _TypeIconData(Icons.cancel_rounded, Colors.red.shade600);
    }

    switch (notification.type) {
      case 'payment':
        return _TypeIconData(Icons.payment_rounded, AppColors.amberAccent);
      case 'new_content':
        return _TypeIconData(Icons.menu_book_rounded, AppColors.secondary);
      default:
        return _TypeIconData(Icons.campaign_rounded, AppColors.primary);
    }
  }

  // ── Tap routing ──────────────────────────────────────────────────────

  Future<void> _onTap() async {
    await NotificationsController.instance.markRead(notification.id);

    switch (notification.type) {
      case 'payment':
        if (_isApproved) {
          // Premium is active — go home so they can use it immediately.
          Get.until((route) => route.isFirst);
        } else {
          // Rejected or pending — let them see the status / retry.
          Get.toNamed(Routes.paymentVerification);
        }
        break;
      case 'new_content':
        await NotificationTestOpener.open(notification.payload);
        break;
      default:
        // Announcement — stay on notifications list (already there).
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = AppHelperFunctions.isDark(context);
    final iconData = _typeIcon;

    return Dismissible(
      key: ValueKey(notification.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismissed(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(
          Icons.delete_outline_rounded,
          color: Colors.white,
          size: 24,
        ),
      ),
      child: GestureDetector(
        onTap: _onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: dark ? AppColors.darkCard : AppColors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _borderColor(dark), width: 1.5),
            boxShadow: dark
                ? []
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Type icon ──────────────────────────────────────────
              Container(
                width: 36,
                height: 36,
                margin: const EdgeInsets.only(right: 12, top: 2),
                decoration: BoxDecoration(
                  color: iconData.color.withValues(alpha: dark ? 0.15 : 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  iconData.icon,
                  size: 18,
                  color: iconData.color,
                ),
              ),

              // ── Content ───────────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title row — with status badge for payment notifications
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              fontWeight: notification.isRead
                                  ? FontWeight.w500
                                  : FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        if (_isApproved)
                          _StatusBadge(
                            label: 'Approved',
                            color: Colors.green.shade600,
                            dark: dark,
                          )
                        else if (_isRejected)
                          _StatusBadge(
                            label: 'Rejected',
                            color: Colors.red.shade600,
                            dark: dark,
                          ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    // Body
                    Text(
                      notification.body,
                      style: TextStyle(
                        fontSize: 13,
                        color: notification.isRead
                            ? AppColors.darkGrey
                            : AppColors.textSecondary,
                      ),
                    ),

                    // Rejection reason (if present)
                    if (_isRejected &&
                        notification.payload['rejection_reason'] != null) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(
                              alpha: dark ? 0.12 : 0.07),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.info_outline_rounded,
                                size: 13,
                                color: Colors.red.shade400),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                notification.payload['rejection_reason']
                                    .toString(),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.red.shade400,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 6),

                    // Timestamp
                    Text(
                      _relativeTime(notification.createdAt),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.darkGrey,
                      ),
                    ),
                  ],
                ),
              ),

              // ── Unread dot ────────────────────────────────────────
              if (!notification.isRead) ...[
                const SizedBox(width: 8),
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(top: 4),
                  decoration: BoxDecoration(
                    color: _isApproved
                        ? Colors.green.shade600
                        : _isRejected
                            ? Colors.red.shade600
                            : AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: dark ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
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

