import 'package:flutter/material.dart';
import 'package:matricmate/utils/constants/app_strings.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';
import 'package:url_launcher/url_launcher.dart';

class TelegramChatButton extends StatelessWidget {
  const TelegramChatButton({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = AppHelperFuntions.isDark(context);
    return Column(
      children: [
        Text(
          "Need help?",
          style: TextStyle(
            color: dark ? AppColors.darkGrey : AppColors.darkerGrey,
          ),
        ),
        const SizedBox(height: 15),
        Align(
          alignment: Alignment.center,
          child: OutlinedButton(
            onPressed: () {
              openUrl(AppTextStrings.telegramChannel);
            },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(50),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.telegram, size: 25, color: Colors.blue),
                SizedBox(width: 10),
                Text("Chat on Telegram", style: TextStyle(color: Colors.teal)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static Future<void> openUrl(String url) async {
    final Uri uri = Uri.parse(url);

    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint("Telegram open failed: $e");
    }
  }
}
