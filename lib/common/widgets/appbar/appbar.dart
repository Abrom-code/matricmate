import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/services.dart';

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
            child: IconButton(
              tooltip: 'Notifications',
              onPressed: onNotificationPressed ?? () {},
              icon: const Icon(Icons.notifications_outlined, color: AppColors.white),
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
    // preferredSize is called before build() — read orientation from
    // Get.context so the Scaffold allocates the right amount of space.
    final ctx = Get.context;
    if (ctx != null) return Size.fromHeight(toolbarHeight(ctx));
    return Size.fromHeight(AppDeviceUtils.getAppBarHeight());
  }
}
