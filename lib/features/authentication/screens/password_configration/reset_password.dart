import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matricmate/features/authentication/controllers/login/reset_password_controller.dart';
import 'package:matricmate/routes/app_routes.dart';
import 'package:matricmate/utils/constants/app_strings.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/constants/sizes.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

class ResetPassword extends GetView<ResetPasswordController> {
  const ResetPassword({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = AppHelperFuntions.isDark(context);
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(
          color: dark ? AppColors.white : AppColors.black,
        ),
        actions: [
          IconButton(
            onPressed: () => Get.offAllNamed(Routes.signIn),
            icon: const Icon(CupertinoIcons.clear),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(AppSizes.defaultSpace),
          child: Column(
            children: [
              const SizedBox(height: AppSizes.spaceBtwItems * 3),

              Text(
                AppTextStrings.changeYourPasswordTitle,
                style: Theme.of(context).textTheme.headlineLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSizes.spaceBtwItems),

              Text(
                AppTextStrings.changeYourPasswordSubTitle,
                style: Theme.of(context).textTheme.labelMedium,
              ),

              const SizedBox(height: AppSizes.spaceBtwItems),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Get.offAllNamed(Routes.signIn),
                  child: Text("Done"),
                ),
              ),

              const SizedBox(height: AppSizes.spaceBtwItems),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () =>
                      controller.sendResetEmail(controller.email.value),
                  child: Obx(
                    () => Text(
                      controller.isSending.value
                          ? "Sending..."
                          : AppTextStrings.resendEmail,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
