import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:matricmate/common/widgets/tiles/list_tile.dart';
import 'package:matricmate/features/exam/screens/premium/widgets/premium_bottom_sheet.dart';
import 'package:matricmate/features/personalization/controllers/user_controller.dart';
import 'package:matricmate/features/personalization/screens/update/update_profile.dart';
import 'package:matricmate/routes/app_routes.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/constants/sizes.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';
import 'package:matricmate/utils/themes/theme_controller.dart';

class AccountSettings extends StatelessWidget {
  const AccountSettings({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = AppHelperFunctions.isDark(context);
    final userCtrl = UserController.instance;
    final isInactive = userCtrl.user.value.isInactive;
    final isPending = userCtrl.user.value.isPending;

    return Obx(() {
      final checking = userCtrl.isCheckingPayment.value;
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSizes.md),
          color: !dark ? AppColors.white : AppColors.darkCard,
        ),
        child: Column(
          children: [
            AppListTile(
              icon: const Icon(Iconsax.user_edit_copy),
              title: 'Edit Profile',
              trailing: const Icon(Icons.keyboard_arrow_right),
              onTap: () => Get.to(() => const EditProfileScreen()),
            ),
            AppListTile(
              icon: const Icon(Iconsax.lock_circle_copy),
              title: 'Change Password',
              trailing: const Icon(Icons.keyboard_arrow_right),
              onTap: () => Get.toNamed(Routes.changePassword),
            ),
            if (isInactive)
              AppListTile(
                icon: const Icon(
                  Icons.workspace_premium,
                  color: Colors.amber,
                ),
                title: 'Upgrade Premium',
                trailing: const Icon(Icons.keyboard_arrow_right),
                onTap: () => Get.bottomSheet(
                  const PremiumBottomSheet(),
                  isScrollControlled: true,
                ),
              ),
            if (isPending)
              AppListTile(
                icon: const Icon(Icons.loop),
                title: 'Refresh Payment',
                trailing: const Icon(Icons.keyboard_arrow_right),
                onTap: checking ? null : () => userCtrl.checkPaymentStatus(),
              ),
            AppListTile(
              icon: const Icon(Icons.help_outlined),
              title: 'Help & Support',
              trailing: const Icon(Icons.keyboard_arrow_right),
              onTap: () {},
            ),
            AppListTile(
              icon: const Icon(Icons.sunny),
              title: 'Change Theme',
              trailing: Switch(
                value: dark,
                onChanged: (value) =>
                    ThemeController.instance.toggleTheme(value),
              ),
            ),
          ],
        ),
      );
    });
  }
}
