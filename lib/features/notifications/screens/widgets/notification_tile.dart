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
  const NotificationTile({super.key, required this.notification});
  final AppNotification notification;

  IconData get _icon {
    switch (notification.type) {
      case 'payment':
        return Icons.receipt_long_rounded;
      case 'new_content':
        return Icons.menu_book_rounded;
      default:
        return Icons.campaign_rounded;
    }
  }

  Future<void> _onTap() async {
    await NotificationsController.instance.markRead(notification.id);

    switch (notification.type) {
      case 'payment':
        Get.toNamed(Routes.paymentVerification);
        break;
      case 'new_content':
        await NotificationTestOpener.open(notification.payload);
        break;
      default:
        // Announcement — bring the user to the notifications list.
        Get.toNamed(Routes.notifications);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = AppHelperFunctions.isDark(context);

    return GestureDetector(
      onTap: _onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: dark ? AppColors.darkCard : AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: notification.isRead
                ? Colors.transparent
                : AppColors.primary.withValues(alpha: 0.4),
          ),
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
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: dark ? 0.2 : 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(_icon, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.body,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
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
            if (!notification.isRead) ...[
              const SizedBox(width: 8),
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 4),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Returns a short relative-time string for notification timestamps.
/// Falls back to absolute date for items older than 7 days.
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
