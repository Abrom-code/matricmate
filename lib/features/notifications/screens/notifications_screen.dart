import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matricmate/common/widgets/appbar/modern_appbar.dart';
import 'package:matricmate/common/widgets/loaders/circular_loading.dart';
import 'package:matricmate/features/notifications/controllers/notifications_controller.dart';
import 'package:matricmate/features/notifications/models/notification_model.dart';
import 'package:matricmate/features/notifications/screens/widgets/notification_section_header.dart';
import 'package:matricmate/features/notifications/screens/widgets/notification_tile.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/constants/sizes.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  NotificationsController get ctrl => NotificationsController.instance;

  @override
  void initState() {
    super.initState();
    ctrl.loadNotifications(syncRemote: true);
  }

  // ── Delete helpers with undo SnackBars ──────────────────────────────

  void _onTileDismissed(AppNotification notification) {
    ctrl.deleteOne(notification.id);

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text('Notification deleted'),
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'Undo',
            textColor: AppColors.primary,
            onPressed: () => ctrl.undoDeleteOne(),
          ),
        ),
      );
  }

  void _confirmClearAll(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Clear all notifications?'),
        content: const Text('This removes all notifications from your device.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              final count = ctrl.notifications.length;
              ctrl.deleteAll();

              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    content: Text(
                      '$count notification${count == 1 ? '' : 's'} cleared',
                    ),
                    duration: const Duration(seconds: 4),
                    action: SnackBarAction(
                      label: 'Undo',
                      textColor: AppColors.primary,
                      onPressed: () => ctrl.undoDeleteAll(),
                    ),
                  ),
                );
            },
            child: const Text(
              'Clear all',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // ── Date-grouped list builder ──────────────────────────────────────

  /// Builds list of notifications grouped by date headers.
  List<Widget> _buildGroupedList(List<AppNotification> items) {
    final widgets = <Widget>[];
    String? lastLabel;

    for (final n in items) {
      final label = NotificationSectionHeader.labelFor(n.createdAt);
      if (label != lastLabel) {
        widgets.add(NotificationSectionHeader(label: label));
        lastLabel = label;
      }
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: AppSizes.spaceBtwItems),
          child: NotificationTile(
            notification: n,
            onDismissed: () => _onTileDismissed(n),
          ),
        ),
      );
    }

    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ModernAppbarWithBuilder(
        title: 'Notifications',
        showBackArrow: true,
        actions: [
          Obx(() {
            if (ctrl.notifications.isEmpty) return const SizedBox.shrink();
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (ctrl.unreadCount.value > 0)
                  TextButton(
                    onPressed: ctrl.markAllRead,
                    child: const Icon(
                      Icons.done_all_rounded,
                      color: AppColors.white,
                      size: 22,
                    ),
                  ),
                IconButton(
                  tooltip: 'Clear all',
                  icon: const Icon(
                    Icons.delete_sweep_rounded,
                    color: AppColors.white,
                    size: 22,
                  ),
                  onPressed: () => _confirmClearAll(context),
                ),
              ],
            );
          }),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => ctrl.loadNotifications(syncRemote: true),
        child: Obx(() {
          if (ctrl.isLoading.value && ctrl.notifications.isEmpty) {
            return const AppCircularLoading(title: 'Loading notifications...');
          }

          if (ctrl.notifications.isEmpty) {
            return ListView(
              children: const [
                SizedBox(height: 120),
                Center(
                  child: Icon(
                    Icons.notifications_none_rounded,
                    size: 48,
                    color: AppColors.darkGrey,
                  ),
                ),
                SizedBox(height: 12),
                Center(
                  child: Text(
                    'No notifications yet',
                    style: TextStyle(color: AppColors.darkGrey),
                  ),
                ),
              ],
            );
          }

          return ListView(
            padding: const EdgeInsets.all(AppSizes.defaultSpace),
            children: _buildGroupedList(ctrl.notifications),
          );
        }),
      ),
    );
  }
}
