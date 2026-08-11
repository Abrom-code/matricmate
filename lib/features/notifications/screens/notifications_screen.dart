import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:matricmate/common/widgets/appbar/modern_appbar.dart';
import 'package:matricmate/common/widgets/loaders/circular_loading.dart';
import 'package:matricmate/features/notifications/controllers/notifications_controller.dart';
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
    // Run diagnose first so the console always shows DB state on open,
    // then do the full sync load.
    ctrl.diagnose().then((_) => ctrl.loadNotifications(syncRemote: true));
  }

  void _confirmClearAll(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Clear all notifications?'),
        content: const Text(
          'This removes all notifications from your device. '
          'They will reappear on next sync.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ctrl.deleteAll();
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
        onRefresh: () async {
          await ctrl.diagnose();
          await ctrl.loadNotifications(syncRemote: true);
        },
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

          return ListView.separated(
            padding: const EdgeInsets.all(AppSizes.defaultSpace),
            itemCount: ctrl.notifications.length,
            separatorBuilder: (_, __) =>
                const SizedBox(height: AppSizes.spaceBtwItems),
            itemBuilder: (_, i) =>
                NotificationTile(notification: ctrl.notifications[i]),
          );
        }),
      ),
    );
  }
}
