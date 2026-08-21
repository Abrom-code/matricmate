import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:matricmate/features/notifications/controllers/notifications_controller.dart';
import 'package:matricmate/routes/app_routes.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/device/device_utility.dart';

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
    this.bottom,
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
  final PreferredSizeWidget? bottom;

  /// Returns the correct toolbar height for the current orientation.
  static double toolbarHeight(BuildContext context) {
    return MediaQuery.orientationOf(context) == Orientation.landscape
        ? _kLandscapeToolbarHeight
        : AppDeviceUtils.getAppBarHeight();
  }

  @override
  Widget build(BuildContext context) {
    final double height = toolbarHeight(context);
    final isPrimaryBg = backgroundColor == AppColors.primary;

    return AppBar(
      automaticallyImplyLeading: false,
      toolbarHeight: height,

      /// Background
      backgroundColor: backgroundColor,
      elevation: 0,
      scrolledUnderElevation: 0,

      /// Status bar style
      systemOverlayStyle: isPrimaryBg
          ? SystemUiOverlayStyle.light
          : (Theme.of(context).brightness == Brightness.dark
              ? SystemUiOverlayStyle.light
              : SystemUiOverlayStyle.dark),

      /// Leading (Back or Custom Icon)
      leading: showBackArrow
          ? Padding(
              padding: const EdgeInsets.only(left: 4),
              child: IconButton(
                onPressed: Get.back,
                tooltip: 'Back',
                icon: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: isPrimaryBg
                        ? AppColors.white.withValues(alpha: 0.15)
                        : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 16,
                      color: leadingIconColor,
                    ),
                  ),
                ),
              ),
            )
          : leadingIcon != null
              ? Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: IconButton(
                    onPressed: leadingOnPressed,
                    icon: Icon(leadingIcon, color: leadingIconColor, size: 20),
                  ),
                )
              : null,

      /// Title
      title: title,
      centerTitle: centerTitle,
      titleSpacing: showBackArrow || leadingIcon != null ? 4 : 16,

      /// Title Style (if using Text widget)
      titleTextStyle: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        color: isPrimaryBg
            ? AppColors.white
            : (Theme.of(context).brightness == Brightness.dark
                ? AppColors.white
                : AppColors.textPrimary),
      ),

      /// Actions
      actions: [
        if (actions != null) ...actions!,
        if (showNotification)
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: _NotificationBell(
              onPressed: onNotificationPressed ??
                  () => Get.toNamed(Routes.notifications),
            ),
          ),
      ],
      actionsPadding: const EdgeInsets.symmetric(horizontal: 4),

      /// Icon Theme
      iconTheme: IconThemeData(
        color: isPrimaryBg
            ? AppColors.white
            : (Theme.of(context).brightness == Brightness.dark
                ? AppColors.white
                : AppColors.textPrimary),
        size: 22,
      ),

      bottom: bottom,
    );
  }

  @override
  Size get preferredSize {
    final ctx = Get.context;
    final baseHeight = ctx != null
        ? toolbarHeight(ctx)
        : AppDeviceUtils.getAppBarHeight();
    final bottomHeight = bottom?.preferredSize.height ?? 0.0;
    return Size.fromHeight(baseHeight + bottomHeight);
  }
}

// ── Notification bell with reactive unread badge ─────────────────────────────

class _NotificationBell extends StatelessWidget {
  const _NotificationBell({required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final count = Get.isRegistered<NotificationsController>()
          ? NotificationsController.instance.unreadCount.value
          : 0;

      return IconButton(
        tooltip: count > 0 ? '$count unread notifications' : 'Notifications',
        onPressed: onPressed,
        icon: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  count > 0
                      ? Icons.notifications_rounded
                      : Icons.notifications_outlined,
                  color: AppColors.white,
                  size: 20,
                ),
              ),
            ),
            if (count > 0)
              Positioned(
                top: -2,
                right: -2,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 1.5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.primary,
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.4),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
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
                      fontWeight: FontWeight.w800,
                      height: 1.1,
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
