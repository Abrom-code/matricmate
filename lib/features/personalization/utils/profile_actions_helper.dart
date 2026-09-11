import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:matricmate/data/services/device_service.dart';
import 'package:matricmate/data/services/payment_config_service.dart';
import 'package:matricmate/features/personalization/controllers/user_controller.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';
import 'package:matricmate/utils/helpers/toast_helper.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class ProfileActionsHelper {
  ProfileActionsHelper._();

  static const String appName = 'MatricET';
  static const String appVersion = '1.0.0';
  static const String packageId = 'com.abopia.matricet';
  static const String fallbackSupportEmail = 'abopiatech@gmail.com';
  static const String fallbackTelegramChannelLink = 'https://t.me/MatricET';
  static const String fallbackTelegramSupportLink = 'https://t.me/matericetbot';
  static const String fallbackTelegramLink = fallbackTelegramChannelLink;
  static const String fallbackPlayStoreUrl =
      'https://play.google.com/store/apps/details?id=$packageId';
  static const String fallbackPrivacyPolicyUrl =
      'https://abopia.github.io/matricmate/privacy_policy.html';

  /// Sends a support email with device and user diagnostic info.
  static Future<void> sendSupportEmail() async {
    final email = PaymentConfigService.instance.supportEmailValue;
    String deviceId = 'N/A';
    try {
      deviceId = await DeviceService.getDeviceId();
    } catch (_) {}

    final user = UserController.instance.user.value;
    final platform = defaultTargetPlatform.name;

    final body = '''
Hi MatricET Support Team,

[Please describe your issue or inquiry here]

---
Diagnostic Info (Please do not delete):
• App: $appName (v$appVersion)
• Platform: $platform
• User ID: ${user.id.isNotEmpty ? user.id : 'Guest'}
• User Email: ${user.email.isNotEmpty ? user.email : 'N/A'}
• Educational Stream: ${user.stream.isNotEmpty ? user.stream : 'N/A'}
• Device ID: $deviceId
''';

    final mailtoUri = Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: {
        'subject': '[$appName Support] Inquiry',
        'body': body,
      },
    );

    try {
      final launched = await launchUrl(
        mailtoUri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        ToastHelper.error(
          'Could not open email app. Please write to $email',
        );
      }
    } catch (e) {
      debugPrint('[ProfileActions] Email launch failed: $e');
      ToastHelper.error(
        'Could not launch mail client. Please contact $email',
      );
    }
  }

  /// Opens a Telegram link (channel, group, or user chat).
  /// First tries native `tg://resolve?domain=...`, falling back to the web link.
  static Future<void> launchTelegram(
    String rawLink, {
    String unavailableMessage = 'Telegram link is not available.',
  }) async {
    final cleanLink = rawLink.trim();

    if (cleanLink.isEmpty) {
      ToastHelper.warning(unavailableMessage);
      return;
    }

    // Extract handle if available (e.g. from https://t.me/matric_mate or @matric_mate)
    String handle = '';
    final parsedUri = Uri.tryParse(cleanLink);
    if (parsedUri != null && parsedUri.pathSegments.isNotEmpty) {
      final first = parsedUri.pathSegments.first;
      if (!first.startsWith('+') && first != 'joinchat') {
        handle = first.replaceFirst('@', '').trim();
      }
    } else if (cleanLink.startsWith('@')) {
      handle = cleanLink.substring(1).trim();
    }

    bool launchedApp = false;
    if (handle.isNotEmpty) {
      final tgUri = Uri.parse('tg://resolve?domain=$handle');
      try {
        if (await canLaunchUrl(tgUri)) {
          launchedApp = await launchUrl(
            tgUri,
            mode: LaunchMode.externalApplication,
          );
        }
      } catch (e) {
        debugPrint('[ProfileActions] tg:// deep link failed: $e');
      }
    }

    if (!launchedApp) {
      final webUrl = cleanLink.startsWith('http')
          ? cleanLink
          : 'https://$cleanLink';
      final webUri = Uri.tryParse(webUrl);
      if (webUri == null) {
        ToastHelper.error('Invalid Telegram link.');
        return;
      }
      try {
        final launched = await launchUrl(
          webUri,
          mode: LaunchMode.externalApplication,
        );
        if (!launched) {
          ToastHelper.error('Could not open Telegram link.');
        }
      } catch (e) {
        debugPrint('[ProfileActions] Telegram web launch failed: $e');
        ToastHelper.error('Could not open browser for Telegram.');
      }
    }
  }

  /// Opens the community Telegram channel (used in Profile -> Join Telegram).
  static Future<void> openTelegramChannel() async {
    final link = PaymentConfigService.instance.telegramChannelLinkValue;
    await launchTelegram(
      link,
      unavailableMessage: 'Telegram channel link is not available.',
    );
  }

  /// Opens the support Telegram chat (used in Payment, Contact Admin, etc.).
  static Future<void> openTelegramSupport() async {
    final link = PaymentConfigService.instance.telegramSupportLinkValue;
    await launchTelegram(
      link,
      unavailableMessage: 'Telegram support link is not available.',
    );
  }

  /// Opens the Telegram channel (kept for backwards compatibility).
  static Future<void> openTelegram() => openTelegramChannel();

  /// Invites friends using share_plus with dynamic share link.
  static Future<void> shareApp() async {
    final rawLink = PaymentConfigService.instance.shareLinkValue;
    final link = rawLink.isNotEmpty ? rawLink : fallbackPlayStoreUrl;

    final inviteMessage =
        'Ace your Ethiopian Matric Exams with $appName! Practice chapter tests, entrance exams, and track your progress.\n\nDownload now: $link';

    try {
      await SharePlus.instance.share(
        ShareParams(
          text: inviteMessage,
          subject: 'Prepare for Ethiopian Matric with $appName',
        ),
      );
    } catch (e) {
      debugPrint('[ProfileActions] Share failed: $e');
      ToastHelper.error('Could not open share options.');
    }
  }

  /// Launches Google Play Store to rate the app, with web fallback.
  static Future<void> rateApp() async {
    final marketUri = Uri.parse('market://details?id=$packageId');
    final webUri = Uri.parse(fallbackPlayStoreUrl);

    try {
      if (await canLaunchUrl(marketUri)) {
        final launched = await launchUrl(
          marketUri,
          mode: LaunchMode.externalApplication,
        );
        if (launched) return;
      }
    } catch (e) {
      debugPrint('[ProfileActions] market:// launch failed: $e');
    }

    try {
      final launched = await launchUrl(
        webUri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        ToastHelper.error('Could not open Google Play Store.');
      }
    } catch (e) {
      debugPrint('[ProfileActions] Play Store web launch failed: $e');
      ToastHelper.error('Could not open Google Play Store.');
    }
  }

  /// Opens the dynamic Privacy Policy URL in an external browser.
  static Future<void> openPrivacyPolicy() async {
    final rawUrl = PaymentConfigService.instance.privacyPolicyUrlValue;
    final url = rawUrl.isNotEmpty ? rawUrl : fallbackPrivacyPolicyUrl;
    final uri = Uri.tryParse(url);

    if (uri == null) {
      ToastHelper.error('Invalid Privacy Policy URL.');
      return;
    }

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        ToastHelper.error('Could not open Privacy Policy link.');
      }
    } catch (e) {
      debugPrint('[ProfileActions] Privacy policy launch failed: $e');
      ToastHelper.error('Could not open Privacy Policy.');
    }
  }

  /// Displays the About dialog with app info and a button to view open-source licenses.
  static void showAboutMatricET(BuildContext context) {
    final dark = AppHelperFunctions.isDark(context);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: dark ? AppColors.darkCard : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: dark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
              width: 1.2,
            ),
          ),
          title: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Iconsax.book_1_copy,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appName,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Version $appVersion (Build 1)',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'MatricET is an educational examination preparation platform designed for Ethiopian Grade 12 students. Practice chapter tests, take timed entrance exams, and monitor academic progress.',
                style: TextStyle(
                  fontSize: 13.5,
                  height: 1.5,
                  color: AppColors.textSecondary,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Developed with pride by Abopia Technologies.',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                showLicensePage(
                  context: context,
                  applicationName: appName,
                  applicationVersion: 'v$appVersion',
                  applicationIcon: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Iconsax.book_1_copy,
                        color: AppColors.primary,
                        size: 28,
                      ),
                    ),
                  ),
                );
              },
              child: const Text('View Licenses'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}
