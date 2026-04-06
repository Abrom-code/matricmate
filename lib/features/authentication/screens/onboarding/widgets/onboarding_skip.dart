import 'package:flutter/material.dart';
import 'package:matricmate/features/authentication/controllers/onboarding/onboardint_controller.dart';
import 'package:matricmate/utils/constants/sizes.dart';

class OnwardingSkip extends StatelessWidget {
  const OnwardingSkip({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = OnboardintController.instance;
    return Positioned(
      top: AppSizes.appBarHeight,
      right: AppSizes.defaultSpace,
      child: TextButton(onPressed: controller.skipPage, child: Text("Skip")),
    );
  }
}
