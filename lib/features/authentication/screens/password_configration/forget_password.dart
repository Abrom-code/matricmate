import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matricmate/features/authentication/controllers/login/forget_password_controller.dart';
import 'package:matricmate/utils/constants/app_strings.dart';
import 'package:matricmate/utils/constants/sizes.dart';
import 'package:matricmate/utils/validators/validators.dart';

class ForgetPassword extends StatelessWidget {
  const ForgetPassword({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ForgetPasswordController());
    return Scaffold(
      appBar: AppBar(),
      body: Padding(
        padding: EdgeInsets.all(AppSizes.defaultSpace),
        child: Form(
          key: controller.forgetPasswordFormkey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppTextStrings.forgetPasswordTitle,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: AppSizes.spaceBtwItems),
              Text(
                AppTextStrings.forgetPasswordSubTitle,
                style: Theme.of(context).textTheme.labelMedium,
              ),
              const SizedBox(height: AppSizes.spaceBtwItems * 2),

              TextFormField(
                controller: controller.email,
                validator: (value) => AppValidator.validateEmail(value),
                onTapOutside: (e) => FocusScope.of(context).unfocus(),
                decoration: InputDecoration(
                  labelText: AppTextStrings.email,
                  prefixIcon: Icon(Icons.arrow_right),
                ),
              ),

              const SizedBox(height: AppSizes.spaceBtwItems * 2),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => controller.resetPassword(),
                  child: const Text(AppTextStrings.submit),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
