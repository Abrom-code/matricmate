import 'package:flutter/material.dart';
import 'package:get/state_manager.dart';
import 'package:matricmate/features/authentication/controllers/signup/signup_controller.dart';
import 'package:matricmate/utils/constants/app_strings.dart';
import 'package:matricmate/utils/constants/sizes.dart';

class TermAndConditions extends StatelessWidget {
  const TermAndConditions({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = SignupController.instance;
    return Row(
      children: [
        Obx(
          () => Checkbox(
            value: controller.isTermsAgreed.value,
            onChanged: (val) => controller.isTermsAgreed.value = val!,
          ),
        ),
        const SizedBox(width: AppSizes.spaceBtwItems),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: '${AppTextStrings.agreeTo} ',
                style: Theme.of(context).textTheme.bodySmall,
              ),

              TextSpan(
                text: AppTextStrings.privacyPolicy,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
