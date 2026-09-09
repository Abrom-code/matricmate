import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:matricmate/common/widgets/tiles/list_tile.dart';
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
          const AppListTile(
            icon: Icon(
              Icons.privacy_tip_outlined,
              color: Color(0xFF0EA5E9),
              size: 20,
            ),
            title: 'Privacy Policy',
            subtitle: 'Review our data privacy commitment',
            trailing: Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textSecondary,
              size: 20,
            ),
            onTap: ProfileActionsHelper.openPrivacyPolicy,
          ),
          divider,
          AppListTile(
            icon: const Icon(
              Iconsax.info_circle_copy,
              color: AppColors.primary,
              size: 18,
            ),
            title: 'About MatricET',
            subtitle: 'Version ${ProfileActionsHelper.appVersion}',
            trailing: const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textSecondary,
              size: 20,
            ),
            onTap: () => ProfileActionsHelper.showAboutMatricET(context),
          ),
          divider,
          AppListTile(
            icon: const Icon(
              Iconsax.document_text_1_copy,
              color: Color(0xFF8B5CF6),
              size: 18,
            ),
            title: 'Open Source Licenses',
            subtitle: 'Third-party libraries & disclosures',
            trailing: const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textSecondary,
              size: 20,
            ),
            onTap: () => showLicensePage(
              context: context,
              applicationName: ProfileActionsHelper.appName,
              applicationVersion: 'v${ProfileActionsHelper.appVersion}',
            ),
          ),
        ],
      ),
    );
  }
}
