import 'package:flutter/material.dart';
import 'package:matricmate/common/widgets/appbar/appbar.dart';
import 'package:matricmate/features/exam/screens/premium/widgets/telegram_chat.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

class PaymentVerificationScreen extends StatelessWidget {
  const PaymentVerificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = AppHelperFuntions.isDark(context);
    return Scaffold(
      appBar: Appbar(
        showBackArrow: true,
        title: Text(
          "Verify Payment",
          style: Theme.of(
            context,
          ).textTheme.headlineSmall!.apply(color: AppColors.white),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 60),

              // Title
              const Text(
                "Payment Verification in Progress",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 15),

              // Subtitle
              const Text(
                "We are verifying your receipt. This usually takes a few hours. "
                "Please click the refresh status button after around 30 minutes. If this couldn't work, please contact the our support on Telegram.",
                textAlign: TextAlign.justify,
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),

              const SizedBox(height: 40),

              // Refresh button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.refresh),
                  label: const Text("Refresh Status"),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 15),

              // Cancel button
              TextButton(
                onPressed: () {},
                child: const Text(
                  "Cancel Payment",
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 15),
              Divider(),
              const SizedBox(height: 15),

              Text(
                "Need help with your Payment?",
                style: TextStyle(
                  color: dark ? AppColors.grey : AppColors.darkerGrey,
                ),
              ),
              const SizedBox(height: 15),

              TelegramChatButton(),
            ],
          ),
        ),
      ),
    );
  }
}
