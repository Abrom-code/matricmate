import 'package:flutter/material.dart';
import 'package:get/get.dart';
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
    ctrl.loadNotifications(syncRemote: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ModernAppbarWithBuilder(
        title: 'Notifications',
        showBackArrow: true,
        actions: [
          Obx(() {
            if (ctrl.unreadCount.value == 0) return const SizedBox.shrink();
            return TextButton(
              onPressed: ctrl.markAllRead,
              child: const Text(
                'Mark all read',
                style: TextStyle(color: AppColors.white, fontSize: 12),
              ),
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
              // ListView (not Center) so pull-to-refresh still works on an
              // empty list.
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
