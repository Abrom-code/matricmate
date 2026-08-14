import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:matricmate/common/widgets/tiles/list_tile.dart';
import 'package:matricmate/data/services/payment_config_service.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/constants/sizes.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';
import 'package:share_plus/share_plus.dart';

class ConnectSupportSection extends StatelessWidget {
  const ConnectSupportSection({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = AppHelperFunctions.isDark(context);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSizes.md),
        color: dark ? AppColors.darkCard : AppColors.white,
      ),
      child: Column(
        children: [
          AppListTile(
            icon: const Icon(Iconsax.send_1_copy, color: AppColors.primary),
            title: 'Join Telegram',
            trailing: const Icon(Icons.keyboard_arrow_right),
            onTap: () => AppHelperFunctions.openUrl(
                PaymentConfigService.instance.telegramLink.value),
          ),
          AppListTile(
            icon: const Icon(Iconsax.star_1_copy, color: Colors.amber),
            title: 'Rate the App',
            trailing: const Icon(Icons.keyboard_arrow_right),
            onTap: () {},
          ),
          Obx(() {
            final shareLink = PaymentConfigService.instance.shareLink.value;
            return AppListTile(
              icon: const Icon(Iconsax.share_copy),
              title: 'Share with Friend',
              trailing: const Icon(Icons.keyboard_arrow_right),
              onTap: shareLink.isEmpty
                  ? null
                  : () => Share.share(
                        'Check out MatricMate to prepare for your exams! $shareLink',
                      ),
            );
          }),
        ],
      ),
    );
  }
}
