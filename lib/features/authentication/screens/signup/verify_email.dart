import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matricmate/data/repositories/authentication/authentication_repository.dart';
import 'package:matricmate/features/authentication/controllers/signup/verify_email_controller.dart';
import 'package:matricmate/utils/constants/app_strings.dart';
import 'package:matricmate/utils/constants/sizes.dart';

class VerifyEmailScreen extends StatelessWidget {
  const VerifyEmailScreen({super.key, this.email});
  final String? email;

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(VerifyEmailController());

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            onPressed: () async {
              await AuthenticationRepository.instance.logout();
            },
            icon: const Icon(CupertinoIcons.clear),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(AppSizes.defaultSpace),
          child: Column(
            children: [
              const SizedBox(height: AppSizes.spaceBtwItems),

              Text(
                AppTextStrings.confirmEmail,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: AppSizes.spaceBtwItems),
              Text(email ?? "", style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: AppSizes.spaceBtwItems),

              Text(
                AppTextStrings.confirmEmailSubTitle,
                style: Theme.of(context).textTheme.labelMedium,
              ),

              const SizedBox(height: AppSizes.spaceBtwItems),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: controller.checkEmailVerification,
                  child: Text(AppTextStrings.continueText),
                ),
              ), // Buttons
              const SizedBox(height: AppSizes.spaceBtwItems),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => controller.sendEmailVerification(),
                  child: const Text(AppTextStrings.resendEmail),
                ),
              ),

              // Column
            ],
          ),
        ),
      ),
    );
  }
}
