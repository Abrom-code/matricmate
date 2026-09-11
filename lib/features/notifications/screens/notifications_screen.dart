import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matricmate/common/widgets/appbar/modern_appbar.dart';
import 'package:matricmate/common/widgets/dialogs/confirm_dialog_box.dart';
import 'package:matricmate/common/widgets/loaders/circular_loading.dart';
import 'package:matricmate/features/notifications/controllers/notifications_controller.dart';
import 'package:matricmate/features/notifications/models/notification_model.dart';
import 'package:matricmate/features/notifications/screens/widgets/notification_filter_sheet.dart';
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
  Timer? _undoSnackBarTimer;

  @override
  void initState() {
    super.initState();
    ctrl.setFilter(NotificationFilter.all);
    ctrl.checkNotificationPermission();
    ctrl.loadNotifications(syncRemote: true);
  }

  @override
  void dispose() {
    _undoSnackBarTimer?.cancel();
    ScaffoldMessenger.maybeOf(context)?.removeCurrentSnackBar();
    ctrl.setFilter(NotificationFilter.all);
    super.dispose();
  }

  // ── Delete helpers with undo SnackBars ──────────────────────────────

  void _showUndoSnackBar({
    required String message,
    required VoidCallback onUndo,
  }) {
    _undoSnackBarTimer?.cancel();

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();

    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        dismissDirection: DismissDirection.horizontal,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        action: SnackBarAction(
          label: 'Undo',
          textColor: const Color(0xFF5EEAD4),
          onPressed: () {
            _undoSnackBarTimer?.cancel();
            messenger.hideCurrentSnackBar();
            onUndo();
          },
        ),
      ),
    );

    // Explicit auto-dismiss timer ensures SnackBar closes even when
    // Android accessibility services force duration to Duration(days: 1)
    _undoSnackBarTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) {
        messenger.hideCurrentSnackBar();
      }
    });
  }

  void _onTileDismissed(AppNotification notification) {
    ctrl.deleteOne(notification.id);
    _showUndoSnackBar(
      message: 'Notification deleted',
      onUndo: () => ctrl.undoDeleteOne(),
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
        _showUndoSnackBar(
          message: '$count notification${count == 1 ? '' : 's'} cleared',
          onUndo: () => ctrl.undoDeleteAll(),
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
    _showUndoSnackBar(
      message: '$count notification${count == 1 ? '' : 's'} deleted',
      onUndo: () => ctrl.undoDeleteSelected(),
    );
  }

  Widget _buildFilteredEmptyState(bool dark, NotificationFilter filter) {
    final IconData icon;
    final String title;
    final String subtitle;
    final Color color = filter.color;

    switch (filter) {
      case NotificationFilter.unread:
        icon = Icons.done_all_rounded;
        title = 'No Unread Notifications';
        subtitle =
            'You\'re completely caught up! All your notifications have been marked as read.';
        break;
      case NotificationFilter.newContent:
        icon = Icons.menu_book_rounded;
        title = 'No New Content Alerts';
        subtitle =
            'New tests, study materials, and subject resources will appear here when posted.';
        break;
      case NotificationFilter.announcements:
        icon = Icons.campaign_rounded;
        title = 'No Announcements';
        subtitle =
            'Important academic announcements, guidelines, and school news will appear here.';
        break;
      case NotificationFilter.challenges:
        icon = Icons.emoji_events_rounded;
        title = 'No Challenge Notifications';
        subtitle =
            'Challenge tournament invites, round updates, and leaderboard rankings will appear here.';
        break;
      case NotificationFilter.payments:
        icon = Icons.account_balance_wallet_rounded;
        title = 'No Payment Notifications';
        subtitle =
            'Payment approvals, verification updates, and subscription receipts will appear here.';
        break;
      case NotificationFilter.all:
        icon = Icons.notifications_none_rounded;
        title = 'No Notifications';
        subtitle = 'You have no notifications right now.';
        break;
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 60),
        Center(
          child: Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: color.withValues(alpha: dark ? 0.20 : 0.10),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: color.withValues(alpha: dark ? 0.35 : 0.22),
                width: 1.5,
              ),
            ),
            child: Center(
              child: Icon(
                icon,
                size: 38,
                color: color,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Center(
          child: Text(
            title,
            style: const TextStyle(
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
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: dark ? AppColors.darkGrey : AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Center(
          child: TextButton.icon(
            onPressed: () => ctrl.setFilter(NotificationFilter.all),
            icon: const Icon(Icons.grid_view_rounded, size: 16),
            label: const Text(
              'View All Notifications',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 10,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(
                  color: AppColors.primary.withValues(alpha: 0.3),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationPermissionBanner(BuildContext context, bool dark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: dark
            ? const Color(0xFF78350F).withValues(alpha: 0.25)
            : const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFF59E0B).withValues(alpha: dark ? 0.45 : 0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF59E0B).withValues(alpha: dark ? 0.08 : 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withValues(alpha: dark ? 0.22 : 0.15),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(
                Icons.notifications_off_rounded,
                color: Color(0xFFD97706),
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Notifications are turned off',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Activate to get challenge alerts, exam results, and study reminders.',
                  style: TextStyle(
                    fontSize: 11.5,
                    height: 1.35,
                    color: dark
                        ? const Color(0xFFD1D5DB)
                        : const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            height: 36,
            child: ElevatedButton(
              onPressed: () => ctrl.promptEnableNotifications(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD97706),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Activate',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dark = AppHelperFunctions.isDark(context);

    return Obx(() {
      final isSelectionMode = ctrl.isSelectionMode;
      final selectedCount = ctrl.selectedIds.length;
      final filteredTotal = ctrl.filteredNotifications.length;
      final allSelected = selectedCount > 0 && selectedCount == filteredTotal;

      return PopScope(
        canPop: !isSelectionMode,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop && isSelectionMode) {
            ctrl.clearSelection();
          }
          if (didPop) {
            ctrl.setFilter(NotificationFilter.all);
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
                    allSelected
                        ? 'All in this view selected'
                        : '$filteredTotal in this view',
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
                    final filter = ctrl.selectedFilter.value;
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
                    if (filter != NotificationFilter.all) {
                      final filteredCount = ctrl.filteredNotifications.length;
                      return Text(
                        '${filter.label} · $filteredCount notification${filteredCount == 1 ? '' : 's'}',
                        style: const TextStyle(
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
                      if (ctrl.isNotificationPermissionGranted.value) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: Tooltip(
                          message: 'Notifications disabled — tap to activate',
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () =>
                                  ctrl.promptEnableNotifications(context),
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEF3C7)
                                      .withValues(alpha: 0.22),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: const Color(0xFFFDE68A)
                                        .withValues(alpha: 0.65),
                                    width: 1,
                                  ),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.notifications_off_rounded,
                                      color: Color(0xFFFDE68A),
                                      size: 16,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Activate',
                                      style: TextStyle(
                                        color: Color(0xFFFDE68A),
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                    Obx(() {
                      if (ctrl.notifications.isEmpty) return const SizedBox.shrink();
                      final isFiltered = ctrl.selectedFilter.value != NotificationFilter.all;

                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // ── Filter Button (right side of AppBar) ─────────
                          Stack(
                            clipBehavior: Clip.none,
                            alignment: Alignment.topRight,
                            children: [
                              Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () => NotificationFilterSheet.show(context),
                                  borderRadius: BorderRadius.circular(10),
                                  child: Container(
                                    width: 34,
                                    height: 34,
                                    decoration: BoxDecoration(
                                      color: isFiltered
                                          ? Colors.white.withValues(alpha: 0.28)
                                          : Colors.white.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Center(
                                      child: Icon(
                                        Icons.tune_rounded,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              if (isFiltered)
                                Positioned(
                                  top: -1,
                                  right: -1,
                                  child: Container(
                                    width: 9,
                                    height: 9,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF5EEAD4),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: AppColors.primary,
                                        width: 1.5,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(width: 8),

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
          body: Obx(() {
            if (ctrl.isLoading.value && ctrl.notifications.isEmpty) {
              return const AppCircularLoading(title: 'Loading notifications...');
            }

            final isPermissionDisabled =
                !ctrl.isNotificationPermissionGranted.value;

            return Column(
              children: [
                if (isPermissionDisabled)
                  _buildNotificationPermissionBanner(context, dark),
                Expanded(
                  child: ctrl.notifications.isEmpty
                      ? RefreshIndicator(
                          color: AppColors.primary,
                          onRefresh: ctrl.refreshAndMarkAllRead,
                          child: ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              const SizedBox(height: 60),
                              Center(
                                child: Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(
                                      alpha: dark ? 0.20 : 0.10,
                                    ),
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(
                                      color: AppColors.primary.withValues(
                                        alpha: dark ? 0.35 : 0.20,
                                      ),
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
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 40),
                                child: Text(
                                  'You have no notifications right now.\nCheck back later for test announcements, updates, and results.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 13,
                                    height: 1.5,
                                    color: dark
                                        ? AppColors.darkGrey
                                        : AppColors.textSecondary,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
                              Center(
                                child: Obx(() {
                                  final isBusy = ctrl.isLoading.value;
                                  return SizedBox(
                                    height: 44,
                                    child: ElevatedButton.icon(
                                      onPressed: isBusy
                                          ? null
                                          : () => ctrl.loadNotifications(
                                                syncRemote: true,
                                              ),
                                      icon: isBusy
                                          ? const SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              ),
                                            )
                                          : const Icon(
                                              Icons.sync_rounded,
                                              size: 18,
                                            ),
                                      label: Text(
                                        isBusy
                                            ? 'Checking...'
                                            : 'Check for Updates',
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
                                          borderRadius:
                                              BorderRadius.circular(12),
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
                              if (isPermissionDisabled) ...[
                                const SizedBox(height: 14),
                                Center(
                                  child: TextButton.icon(
                                    onPressed: () =>
                                        ctrl.promptEnableNotifications(context),
                                    icon: const Icon(
                                      Icons.notifications_active_rounded,
                                      size: 16,
                                      color: Color(0xFFD97706),
                                    ),
                                    label: const Text(
                                      'Turn on Notifications',
                                      style: TextStyle(
                                        color: Color(0xFFD97706),
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          color: AppColors.primary,
                          onRefresh: ctrl.refreshAndMarkAllRead,
                          child: ctrl.filteredNotifications.isEmpty
                              ? _buildFilteredEmptyState(
                                  dark,
                                  ctrl.selectedFilter.value,
                                )
                              : ListView(
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    12,
                                    16,
                                    32,
                                  ),
                                  children: _buildGroupedList(
                                    ctrl.filteredNotifications,
                                  ),
                                ),
                        ),
                ),
              ],
            );
          }),
        ),
      );
    });
  }
}

