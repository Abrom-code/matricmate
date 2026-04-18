import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matricmate/features/personalization/screen/profile/widgets/profile_tile.dart';
import 'package:matricmate/features/personalization/screen/update/update_profile.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/constants/sizes.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';
import 'package:matricmate/utils/themes/theme_controller.dart';

class AccountSettings extends StatelessWidget {
  const AccountSettings({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = AppHelperFuntions.isDark(context);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSizes.md),
        color: !dark ? AppColors.white : AppColors.black,
      ),
      child: Column(
        children: [
          ProfileTile(
            icon: Icon(Icons.person),
            title: "Edit Profile",
            trailing: Icon(Icons.keyboard_arrow_right),

            onTap: () => Get.to(() => EditProfileScreen()),
          ),
          ProfileTile(
            icon: Icon(Icons.lock),
            title: "Change Password",
            trailing: Icon(Icons.keyboard_arrow_right),
            onTap: () {},
          ),
          ProfileTile(
            icon: Icon(Icons.help),
            title: "Help & Support",
            trailing: Icon(Icons.keyboard_arrow_right),
            onTap: () {},
          ),
          ProfileTile(
            icon: Icon(Icons.sunny),
            title: "Change Theme",
            trailing: Switch(
              value: dark,
              onChanged: (value) => ThemeController.instance.toogleTheme(value),
            ),
          ),
        ],
      ),
    );
  }
}
