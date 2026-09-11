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

    const telegramBlue = Color(0xFF0284C7);
    const telegramLightBlue = Color(0xFF38BDF8);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => ProfileActionsHelper.openTelegramSupport(),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: dark ? const Color(0xFF131B26) : const Color(0xFFF0F9FF),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: dark
                  ? telegramBlue.withValues(alpha: 0.30)
                  : const Color(0xFFBAE6FD),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: telegramBlue.withValues(alpha: dark ? 0.10 : 0.05),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Need help or question?',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                        color:
                            dark ? AppColors.textWhite : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Obx(() {
                      final _ = PaymentConfigService
                          .instance.telegramSupportLink.value;
                      return Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: 'Contact with ',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                                color: dark
                                    ? const Color(0xFF94A3B8)
                                    : const Color(0xFF64748B),
                              ),
                            ),
                            TextSpan(
                              text: telegramUsername,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: dark ? telegramLightBlue : telegramBlue,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF38BDF8),
                      Color(0xFF0284C7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: telegramBlue.withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.send_rounded,
                    size: 19,
                    color: Colors.white,
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
