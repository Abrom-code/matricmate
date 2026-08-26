import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matricmate/common/widgets/appbar/modern_appbar.dart';
import 'package:matricmate/common/widgets/dialogs/confirm_dialog_box.dart';
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
    AppDialogBoxes.showOkCancelDialog(
      context: context,
      title: 'Clear All Notifications?',
      subtitle:
          'This will remove all notifications from your device. You can undo this action immediately after.',
      confirmText: 'Clear All',
      icon: Icons.delete_outline_rounded,
      isDestructive: true,
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

    void _deleteSelectedWithUndo() {
    final count = ctrl.selectedIds.length;
    if (count == 0) return;

    ctrl.deleteSelected();

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            '$count notification${count == 1 ? '' : 's'} deleted',
          ),
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          action: SnackBarAction(
            label: 'Undo',
            textColor: const Color(0xFF5EEAD4),
            onPressed: () => ctrl.undoDeleteSelected(),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final dark = AppHelperFunctions.isDark(context);

    return Obx(() {
      final isSelectionMode = ctrl.isSelectionMode;
      final selectedCount = ctrl.selectedIds.length;
      final totalCount = ctrl.notifications.length;
      final allSelected = selectedCount > 0 && selectedCount == totalCount;

      return PopScope(
        canPop: !isSelectionMode,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop && isSelectionMode) {
            ctrl.clearSelection();
          }
        },
        child: Scaffold(
          backgroundColor: dark ? AppColors.dark : const Color(0xFFF8FAFC),
          appBar: isSelectionMode
              ? ModernAppbarWithBuilder(
                  title: '$selectedCount Selected',
                  showBackArrow: false,
                  leadingIcon: Icons.close_rounded,
                  leadingOnPressed: ctrl.clearSelection,
                  subtitleBuilder: (_) => Text(
                    allSelected ? 'All notifications selected' : '$totalCount total',
                    style: const TextStyle(
                      color: Color(0xFFD1FAE5),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  actions: [
                    // Toggle Select All / Deselect All
                    IconButton(
                      tooltip: allSelected ? 'Deselect All' : 'Select All',
                      icon: Icon(
                        allSelected
                            ? Icons.deselect_rounded
                            : Icons.select_all_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: allSelected ? ctrl.clearSelection : ctrl.selectAll,
                    ),
                    // Mark Selected as Read
                    IconButton(
                      tooltip: 'Mark as read',
                      icon: const Icon(
                        Icons.mark_email_read_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: ctrl.markSelectedAsRead,
                    ),
                    // Delete Selected
                    IconButton(
                      tooltip: 'Delete selected',
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: _deleteSelectedWithUndo,
                    ),
                    const SizedBox(width: 8),
                  ],
                )
              : ModernAppbarWithBuilder(
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
                    const SizedBox(height: 80),
                    Center(
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: dark ? 0.20 : 0.10),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: dark ? 0.35 : 0.20),
                            width: 1.5,
                          ),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.notifications_none_rounded,
                            size: 40,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Center(
                      child: Text(
                        'All Caught Up!',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Text(
                        'You have no notifications right now.\nCheck back later for test announcements, updates, and results.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.5,
                          color: dark ? AppColors.darkGrey : AppColors.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Center(
                      child: Obx(() {
                        final isBusy = ctrl.isLoading.value;
                        return SizedBox(
                          height: 44,
                          child: ElevatedButton.icon(
                            onPressed: isBusy
                                ? null
                                : () => ctrl.loadNotifications(syncRemote: true),
                            icon: isBusy
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.sync_rounded, size: 18),
                            label: Text(
                              isBusy ? 'Checking...' : 'Check for Updates',
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              side: const BorderSide(
                                color: AppColors.primary,
                                width: 1.5,
                              ),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 22,
                                vertical: 10,
                              ),
                            ),
                          ),
                        );
                      }),
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
        ),
      );
    });
  }
}

