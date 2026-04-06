import 'package:flutter/material.dart';
import 'package:matricmate/features/authentication/controllers/onboarding/onboardint_controller.dart';
import 'package:matricmate/utils/constants/sizes.dart';

class OnBoardingButton extends StatelessWidget {
  const OnBoardingButton({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = OnboardintController.instance;
    return Positioned(
      right: AppSizes.defaultSpace,
      bottom: 20,
      child: ElevatedButton(
        onPressed: () => controller.nextPage(),
        child: Icon(Icons.arrow_right_alt, size: 30),
      ),
    );
  }
}
