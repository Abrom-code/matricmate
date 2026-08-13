import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matricmate/common/widgets/appbar/appbar.dart';
import 'package:matricmate/features/exam/screens/premium/widgets/telegram_chat.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/constants/sizes.dart';

class ContactAdminScreen extends StatelessWidget {
  const ContactAdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: Appbar(
        showBackArrow: true,
        title: Text(
          'Contact Admin',
          style: Theme.of(context).textTheme.headlineSmall!.apply(color: AppColors.white),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.defaultSpace),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              
              const Icon(
                Icons.warning_amber_rounded,
                size: 80,
                color: Colors.amber,
              ),
              
              const SizedBox(height: AppSizes.spaceBtwItems),
              
              Text(
                'Upload Limit Reached',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: AppSizes.spaceBtwItems),
              
              const Text(
                'You have reached the maximum number of receipt upload attempts. Please contact our support team to verify your payment or reset your upload limit.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.darkGrey,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              
              const SizedBox(height: AppSizes.spaceBtwSections),
              
              const TelegramChatButton(),
              
              const SizedBox(height: AppSizes.spaceBtwSections),
              
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Get.until((route) => route.isFirst),
                  child: const Text('Back to Home'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
