import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:matricmate/common/widgets/tiles/list_tile.dart';
import 'package:matricmate/data/services/payment_config_service.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';
import 'package:share_plus/share_plus.dart';

class ConnectSupportSection extends StatelessWidget {
  const ConnectSupportSection({super.key});

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
            icon: const Icon(Iconsax.send_1_copy, color: AppColors.primary, size: 18),
            title: 'Join Telegram',
            trailing: const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textSecondary,
              size: 20,
            ),
            onTap: () => AppHelperFunctions.openUrl(
              PaymentConfigService.instance.telegramLink.value,
            ),
          ),
          divider,
          AppListTile(
            icon: const Icon(Iconsax.star_1_copy, color: Color(0xFFF59E0B), size: 18),
            title: 'Rate the App',
            trailing: const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textSecondary,
              size: 20,
            ),
            onTap: () {},
          ),
          divider,
          Obx(() {
            final shareLink = PaymentConfigService.instance.shareLink.value;
            return AppListTile(
              icon: const Icon(Iconsax.share_copy, size: 18),
              title: 'Share with Friend',
              trailing: const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondary,
                size: 20,
              ),
              onTap: shareLink.isEmpty
                  ? null
                  : () => SharePlus.instance.share(
                      ShareParams(
                        text:
                            'Check out MatricET to prepare for your exams! $shareLink',
                      ),
                    ),
            );
          }),
        ],
      ),
    );
  }
}
