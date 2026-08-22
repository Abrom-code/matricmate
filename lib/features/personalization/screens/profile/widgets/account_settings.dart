import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:matricmate/common/widgets/tiles/list_tile.dart';
import 'package:matricmate/common/widgets/exam/premium_bottom_sheet.dart';
import 'package:matricmate/data/services/payment_config_service.dart';
import 'package:matricmate/features/personalization/controllers/user_controller.dart';
import 'package:matricmate/routes/app_routes.dart';
import 'package:matricmate/utils/constants/colors.dart';
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
      final divider = Divider(
        height: 1,
        thickness: 0.8,
        indent: 58,
        color: dark
            ? Colors.white.withValues(alpha: 0.06)
            : const Color(0xFFF1F5F9),
      );

      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: dark ? AppColors.darkCard : AppColors.white,
          border: Border.all(
            color: dark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: dark ? 0.2 : 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            AppListTile(
              icon: const Icon(Iconsax.user_edit_copy, size: 18),
              title: 'Edit Profile',
              trailing: const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondary,
                size: 20,
              ),
              onTap: () => Get.toNamed(Routes.editProfile),
            ),
            divider,
            AppListTile(
              icon: const Icon(Iconsax.lock_circle_copy, size: 18),
              title: 'Change Password',
              trailing: const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondary,
                size: 20,
              ),
              onTap: () => Get.toNamed(Routes.changePassword),
            ),
            divider,
            if (userCtrl.user.value.isActive) ...[
              AppListTile(
                icon: const Icon(
                  Icons.workspace_premium_rounded,
                  color: Color(0xFFF59E0B),
                  size: 20,
                ),
                title: 'Premium Member',
                subtitle: userCtrl.user.value.remainingDaysText.isNotEmpty
                    ? userCtrl.user.value.remainingDaysText
                    : 'Active Access',
                trailing: const Icon(
                  Icons.verified_rounded,
                  color: Color(0xFF10B981),
                  size: 20,
                ),
                onTap: null,
              ),
              divider,
            ],
            if (isInactive) ...[
              Obx(() {
                final price = PaymentConfigService.instance
                    .getPriceForPlan('6_months', 150);
                return AppListTile(
                  icon: const Icon(
                    Icons.workspace_premium_rounded,
                    color: Color(0xFFF59E0B),
                    size: 20,
                  ),
                  title: 'Upgrade Premium',
                  subtitle: 'Starting from $price ETB',
                  trailing: const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                  onTap: () => Get.bottomSheet(
                    const PremiumBottomSheet(),
                    isScrollControlled: true,
                  ),
                );
              }),
              divider,
            ],
            if (isPending) ...[
              AppListTile(
                icon: const Icon(Icons.sync_rounded, size: 18),
                title: 'Refresh Payment',
                trailing: const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
                onTap: checking ? null : () => userCtrl.checkPaymentStatus(),
              ),
              divider,
            ],
            AppListTile(
              icon: const Icon(Icons.help_outline_rounded, size: 18),
              title: 'Help & Support',
              trailing: const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondary,
                size: 20,
              ),
              onTap: () {},
            ),
            divider,
            AppListTile(
              icon: Icon(
                dark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                size: 18,
              ),
              title: 'Dark Mode',
              trailing: Transform.scale(
                scale: 0.85,
                child: Switch(
                  value: dark,
                  activeThumbColor: AppColors.primary,
                  onChanged: (value) =>
                      ThemeController.instance.toggleTheme(value),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}
