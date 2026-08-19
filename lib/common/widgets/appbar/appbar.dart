import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/services.dart';

import 'package:matricmate/features/notifications/controllers/notifications_controller.dart';
import 'package:matricmate/routes/app_routes.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/device/device_utility.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

/// Compact toolbar height used in landscape to save vertical space.
const double _kLandscapeToolbarHeight = 40.0;

class Appbar extends StatelessWidget implements PreferredSizeWidget {
  const Appbar({
    super.key,
    this.title,
    this.showBackArrow = false,
    this.actions,
    this.leadingIcon,
    this.leadingOnPressed,
    this.centerTitle = false,
    this.backgroundColor = AppColors.primary,
    this.leadingIconColor = AppColors.white,
    this.showNotification = false,
    this.onNotificationPressed,
  });

  final Widget? title;
  final bool showBackArrow;
  final List<Widget>? actions;
  final IconData? leadingIcon;
  final VoidCallback? leadingOnPressed;
  final bool centerTitle;
  final Color backgroundColor;
  final Color leadingIconColor;
  final bool showNotification;
  final VoidCallback? onNotificationPressed;

  /// Returns the correct toolbar height for the current orientation.
  static double toolbarHeight(BuildContext context) {
    return MediaQuery.orientationOf(context) == Orientation.landscape
        ? _kLandscapeToolbarHeight
        : AppDeviceUtils.getAppBarHeight();
  }

  @override
  Widget build(BuildContext context) {
    final bool dark = AppHelperFunctions.isDark(context);
    final double height = toolbarHeight(context);

    return AppBar(
      automaticallyImplyLeading: false,
      toolbarHeight: height,

      /// Background
      backgroundColor: backgroundColor,
      elevation: 0,
      scrolledUnderElevation: 0,

      /// Status bar style
      systemOverlayStyle: SystemUiOverlayStyle.light,

      /// Leading (Back or Custom Icon)
      leading: showBackArrow
          ? IconButton(
              onPressed: Get.back,
              icon: Icon(Icons.arrow_back_ios_new, color: leadingIconColor),
            )
          : leadingIcon != null
          ? IconButton(
              onPressed: leadingOnPressed,
              icon: Icon(leadingIcon, color: leadingIconColor),
            )
          : null,

      /// Title
      title: title,
      centerTitle: centerTitle,
      titleSpacing: 8,

      /// Title Style (if using Text widget)
      titleTextStyle: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: dark ? AppColors.white : AppColors.black,
      ),

      /// Actions
      actions: [
        if (actions != null) ...actions!,
        if (showNotification)
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: _NotificationBell(
              onPressed:
                  onNotificationPressed ??
                  () => Get.toNamed(Routes.notifications),
            ),
          ),
      ],
      actionsPadding: const EdgeInsets.symmetric(horizontal: 4),

      /// Icon Theme (affects actions icons too)
      iconTheme: const IconThemeData(color: AppColors.white),
    );
  }

  @override
  Size get preferredSize {
    // Read orientation from Get.context before build
    final ctx = Get.context;
    if (ctx != null) return Size.fromHeight(toolbarHeight(ctx));
    return Size.fromHeight(AppDeviceUtils.getAppBarHeight());
  }
}

// ── Notification bell with reactive unread badge ─────────────────────────────

class _NotificationBell extends StatelessWidget {
  const _NotificationBell({required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // Only read controller if registered to avoid unhandled crash
      final count = Get.isRegistered<NotificationsController>()
          ? NotificationsController.instance.unreadCount.value
          : 0;

      return IconButton(
        tooltip: count > 0 ? '$count unread' : 'Notifications',
        onPressed: onPressed,
        icon: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(
              count > 0
                  ? Icons.notifications_rounded
                  : Icons.notifications_outlined,
              color: AppColors.white,
              size: 24,
            ),
            if (count > 0)
              Positioned(
                top: -4,
                right: -6,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.shade600,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 14,
                  ),
                  child: Text(
                    count > 9 ? '9+' : '$count',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      );
    });
  }
}
