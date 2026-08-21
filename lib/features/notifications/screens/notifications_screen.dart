import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matricmate/common/widgets/appbar/modern_appbar.dart';
import 'package:matricmate/common/widgets/loaders/circular_loading.dart';
import 'package:matricmate/features/notifications/controllers/notifications_controller.dart';
import 'package:matricmate/features/notifications/models/notification_model.dart';
import 'package:matricmate/features/notifications/screens/widgets/notification_section_header.dart';
import 'package:matricmate/features/notifications/screens/widgets/notification_tile.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

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
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          action: SnackBarAction(
            label: 'Undo',
            textColor: const Color(0xFF5EEAD4),
            onPressed: () => ctrl.undoDeleteOne(),
          ),
        ),
      );
  }

  void _confirmClearAll(BuildContext context) {
    final dark = AppHelperFunctions.isDark(context);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: dark ? AppColors.darkCard : AppColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: dark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
            width: 1.2,
          ),
        ),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: dark ? 0.2 : 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: Icon(
                  Icons.delete_outline_rounded,
                  color: Color(0xFFEF4444),
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Clear All?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        content: Text(
          'This will remove all notifications from your device. You can undo this action immediately after.',
          style: TextStyle(
            fontSize: 13.5,
            color: dark ? AppColors.darkGrey : AppColors.textSecondary,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: dark ? AppColors.white : const Color(0xFF0F172A),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
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
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    action: SnackBarAction(
                      label: 'Undo',
                      textColor: const Color(0xFF5EEAD4),
                      onPressed: () => ctrl.undoDeleteAll(),
                    ),
                  ),
                );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: const Text(
              'Clear All',
              style: TextStyle(fontWeight: FontWeight.w700),
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
          padding: const EdgeInsets.only(bottom: 10),
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
    final dark = AppHelperFunctions.isDark(context);

    return Scaffold(
      backgroundColor: dark ? AppColors.dark : const Color(0xFFF8FAFC),
      appBar: ModernAppbarWithBuilder(
        title: 'Notifications',
        showBackArrow: true,
        subtitleBuilder: (_) => Obx(() {
          final unread = ctrl.unreadCount.value;
          final total = ctrl.notifications.length;
          if (total == 0) {
            return const Text(
              'All caught up',
              style: TextStyle(
                color: Color(0xFFD1FAE5),
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
              ),
            );
          }
          return Text(
            unread > 0 ? '$unread unread · $total total' : '$total notifications',
            style: const TextStyle(
              color: Color(0xFFD1FAE5),
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
            ),
          );
        }),
        actions: [
          Obx(() {
            if (ctrl.notifications.isEmpty) return const SizedBox.shrink();
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (ctrl.unreadCount.value > 0) ...[
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: ctrl.markAllRead,
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.done_all_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _confirmClearAll(context),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.delete_sweep_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
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
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const SizedBox(height: 100),
                Center(
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: dark ? 0.22 : 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.notifications_none_rounded,
                        size: 36,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Center(
                  child: Text(
                    'All Caught Up!',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    'You have no notifications right now. Check back later for test announcements, updates, and results.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.45,
                      color: dark ? AppColors.darkGrey : AppColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Center(
                  child: ElevatedButton.icon(
                    onPressed: () => ctrl.loadNotifications(syncRemote: true),
                    icon: const Icon(Icons.sync_rounded, size: 16),
                    label: const Text('Check for Updates'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                  ),
                ),
              ],
            );
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: _buildGroupedList(ctrl.notifications),
          );
        }),
      ),
    );
  }
}

