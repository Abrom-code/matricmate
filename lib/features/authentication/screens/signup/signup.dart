import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matricmate/features/authentication/screens/signup/widgets/signup_form.dart';
import 'package:matricmate/routes/app_routes.dart';
import 'package:matricmate/utils/constants/app_strings.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/constants/sizes.dart';

class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.defaultSpace),
          child: Column(
            children: [
              Text(
                AppTextStrings.signIn,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: AppSizes.spaceBtwSections),

              const SignupForm(),

              const SizedBox(height: AppSizes.defaultSpace),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Already have an account? ',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  TextButton(
                    onPressed: () => Get.offNamed(Routes.signIn),
                    child: Text(
                      'LOGIN',
                      style: Theme.of(
                        context,
                      ).textTheme.titleMedium!.apply(color: AppColors.primary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.defaultSpace),
            ],
          ),
        ),
      ),
    );
  }
}
