import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:matricmate/common/widgets/tiles/list_tile.dart';
import 'package:matricmate/features/personalization/screens/profile/about_screen.dart';
import 'package:matricmate/features/personalization/utils/profile_actions_helper.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

class LegalAboutSection extends StatelessWidget {
  const LegalAboutSection({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = AppHelperFunctions.isDark(context);
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
            icon: const Icon(
              Iconsax.info_circle_copy,
              color: AppColors.primary,
              size: 19,
            ),
            title: 'About ${ProfileActionsHelper.appName}',
            subtitle:
                'Version ${ProfileActionsHelper.appVersion} • Features & legal info',
            trailing: const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textSecondary,
              size: 20,
            ),
            onTap: () => Get.to(() => const AboutScreen()),
          ),
          divider,
          Obx(() {
            final isChecking = ProfileActionsHelper.isCheckingUpdate.value;
            final hasUpdate = ProfileActionsHelper.hasUpdateAvailable.value;
            final newVersion = ProfileActionsHelper.availableVersion.value;

            String subtitleText;
            if (isChecking) {
              subtitleText = 'Checking for latest version...';
            } else if (hasUpdate && newVersion.isNotEmpty) {
              subtitleText = 'Update available! Tap to install v$newVersion';
            } else {
              subtitleText =
                  'Current: v${ProfileActionsHelper.appVersion} • Tap to check';
            }

            Widget trailingWidget;
            if (isChecking) {
              trailingWidget = const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              );
            } else if (hasUpdate) {
              trailingWidget = Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B)
                      .withValues(alpha: dark ? 0.22 : 0.14),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFF59E0B)
                        .withValues(alpha: dark ? 0.45 : 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF59E0B),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      newVersion.isNotEmpty ? 'v$newVersion' : 'New',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: dark
                            ? const Color(0xFFFBBF24)
                            : const Color(0xFFD97706),
                      ),
                    ),
                  ],
                ),
              );
            } else {
              trailingWidget = const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondary,
                size: 20,
              );
            }

            return AppListTile(
              icon: Icon(
                Icons.system_update_rounded,
                color: hasUpdate ? const Color(0xFFF59E0B) : AppColors.primary,
                size: 19,
              ),
              title: 'Check for Updates',
              subtitle: subtitleText,
              trailing: trailingWidget,
              onTap: isChecking
                  ? null
                  : () => ProfileActionsHelper.checkForUpdates(context),
            );
          }),
        ],
      ),
    );
  }
}
