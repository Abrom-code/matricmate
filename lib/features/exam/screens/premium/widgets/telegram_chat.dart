import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matricmate/data/services/payment_config_service.dart';
import 'package:matricmate/features/personalization/utils/profile_actions_helper.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

class TelegramChatButton extends StatelessWidget {
  const TelegramChatButton({super.key});

  static String get telegramUsername {
    final link = PaymentConfigService.instance.telegramSupportLinkValue;
    if (link.isEmpty) return '@matericetbot';
    final clean = link
        .replaceAll(RegExp(r'https?:\/\/', caseSensitive: false), '')
        .replaceAll(RegExp(r't\.me\/', caseSensitive: false), '')
        .replaceAll(RegExp(r'telegram\.me\/', caseSensitive: false), '')
        .replaceAll('/', '')
        .trim();
    if (clean.isEmpty) return '@matericetbot';
    return clean.startsWith('@') ? clean : '@$clean';
  }

  @override
  Widget build(BuildContext context) {
    final dark = AppHelperFunctions.isDark(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => ProfileActionsHelper.openTelegramSupport(),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: dark ? AppColors.darkSurface : AppColors.lightCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: dark ? AppColors.darkBorder : AppColors.borderPrimary,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Need help?',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color:
                            dark ? AppColors.textWhite : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Obx(() {
                      final _ = PaymentConfigService
                          .instance.telegramSupportLink.value;
                      return Text(
                        telegramUsername,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: dark
                              ? const Color(0xFF38BDF8)
                              : const Color(0xFF0284C7),
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.send_rounded,
                    size: 20,
                    color: AppColors.info,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Future<void> openUrl(String url) async {
    await ProfileActionsHelper.launchTelegram(
      url,
      unavailableMessage: 'Telegram support link is not available.',
    );
  }
}
