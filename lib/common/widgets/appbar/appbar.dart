import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/services.dart';

import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/device/device_utility.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

class Appbar extends StatelessWidget implements PreferredSizeWidget {
  const Appbar({
    super.key,
    this.title,
    this.showBackArrow = false,
    this.actions,
    this.leadingIcon,
    this.leadingOnPressed,
    this.centerTitle = false,
  });

  final Widget? title;
  final bool showBackArrow;
  final List<Widget>? actions;
  final IconData? leadingIcon;
  final VoidCallback? leadingOnPressed;
  final bool centerTitle;

  @override
  Widget build(BuildContext context) {
    final bool dark = AppHelperFuntions.isDark(context);

    return AppBar(
      automaticallyImplyLeading: false,

      /// Background
      backgroundColor: AppColors.primary,
      elevation: 0,
      scrolledUnderElevation: 0,

      /// Status bar style
      systemOverlayStyle: SystemUiOverlayStyle.light,

      /// Leading (Back or Custom Icon)
      leading: showBackArrow
          ? IconButton(
              onPressed: Get.back,
              icon: Icon(Icons.arrow_back_ios_new, color: AppColors.white),
            )
          : leadingIcon != null
          ? IconButton(
              onPressed: leadingOnPressed,
              icon: Icon(leadingIcon, color: AppColors.white),
            )
          : null,

      /// Title
      title: title,
      centerTitle: centerTitle,

      /// Title Style (if using Text widget)
      titleTextStyle: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: dark ? AppColors.white : AppColors.black,
      ),

      /// Actions
      actions: actions,

      /// Icon Theme (affects actions icons too)
      iconTheme: IconThemeData(color: AppColors.white),

      
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(AppDeviceUtils.getAppBarHeight());
}
