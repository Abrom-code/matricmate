import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matricmate/common/widgets/loaders/circular_loading.dart';
import 'package:matricmate/features/authentication/controllers/authentication_controller.dart';
import 'package:matricmate/features/authentication/controllers/signup/verify_email_controller.dart';
import 'package:matricmate/utils/constants/app_strings.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/constants/sizes.dart';

class VerifyEmailScreen extends GetView<VerifyEmailController> {
  const VerifyEmailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            onPressed: () => Get.find<AuthenticationController>().logout(),
            icon: const Icon(CupertinoIcons.clear),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.defaultSpace),
          child: Column(
            children: [
              const SizedBox(height: AppSizes.spaceBtwItems),

              Text(
                AppTextStrings.confirmEmail,
                style: Theme.of(context).textTheme.headlineMedium,
              ),

              const SizedBox(height: AppSizes.spaceBtwItems),

              Obx(
                () => Text(
                  controller.email.value,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),

              const SizedBox(height: AppSizes.spaceBtwItems),

              Text(
                AppTextStrings.confirmEmailSubTitle,
                style: Theme.of(context).textTheme.labelMedium,
              ),
              const SizedBox(height: AppSizes.spaceBtwItems),

              RichText(
                text: TextSpan(
                  text:
                      "If you don’t see the verification email in your inbox, kindly check your ",
                  style: Theme.of(context).textTheme.labelMedium,
                  children: [
                    TextSpan(
                      text: "Spam folder".toUpperCase(),
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber,
                      ),
                    ),
                    TextSpan(text: " as well."),
                  ],
                ),
              ),

              const SizedBox(height: AppSizes.spaceBtwSections),

              SizedBox(
                width: double.infinity,
                child: Obx(
                  () => ElevatedButton(
                    onPressed: !controller.isChecking.value
                        ? controller.checkEmailVerification
                        : null,
                    child: controller.isChecking.value
                        ? AppCircularBottonLoading()
                        : Text(
                            "I've Verified",
                            style: TextStyle(color: AppColors.white),
                          ),
                  ),
                ),
              ),

              const SizedBox(height: AppSizes.spaceBtwItems),

              SizedBox(
                width: double.infinity,
                child: Obx(() {
                  final isResending = controller.isResending.value;
                  return TextButton(
                    onPressed: isResending
                        ? null
                        : controller.sendEmailVerification,
                    child: isResending
                        ? AppCircularBottonLoading(color: AppColors.primary)
                        : Text(AppTextStrings.resendEmail),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
