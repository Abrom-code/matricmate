import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:matricmate/common/widgets/tiles/list_tile.dart';
import 'package:matricmate/features/exam/screens/premium/widgets/premium_bottom_sheet.dart';
import 'package:matricmate/features/personalization/controller/user_controller.dart';
import 'package:matricmate/features/personalization/screen/update/update_profile.dart';
import 'package:matricmate/routes/app_routes.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/constants/sizes.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';
import 'package:matricmate/utils/themes/theme_controller.dart';

class AccountSettings extends StatelessWidget {
  const AccountSettings({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = AppHelperFuntions.isDark(context);
    final isInactive = UserController.instance.user.value.isInactive;
    final isPending = UserController.instance.user.value.isPending;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSizes.md),
        color: !dark ? AppColors.white : AppColors.black,
      ),
      child: Column(
        children: [
          AppListTile(
            icon: Icon(Iconsax.user_edit_copy),
            title: "Edit Profile",
            trailing: Icon(Icons.keyboard_arrow_right),

            onTap: () => Get.to(() => EditProfileScreen()),
          ),
          AppListTile(
            icon: Icon(Iconsax.lock_circle_copy),
            title: "Change Password",
            trailing: Icon(Icons.keyboard_arrow_right),
            onTap: () => Get.toNamed(Routes.changePassword),
          ),

          if (isInactive)
            AppListTile(
              icon: Icon(Icons.workspace_premium, color: Colors.amber),
              title: "Upgrade Premium",
              trailing: Icon(Icons.keyboard_arrow_right),
              onTap: () {
                Get.bottomSheet(
                  const PremiumBottomSheet(),
                  isScrollControlled: true,
                );
              },
            ),
          if (isPending)
            AppListTile(
              icon: Icon(Icons.loop),
              title: "Refresh Payment",
              trailing: Icon(Icons.keyboard_arrow_right),
              onTap: () async {
                await UserController.instance.checkPaymentStatus();
              },
            ),
          AppListTile(
            icon: Icon(Icons.help_outlined),
            title: "Help & Support",
            trailing: Icon(Icons.keyboard_arrow_right),
            onTap: () {},
          ),
          AppListTile(
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
