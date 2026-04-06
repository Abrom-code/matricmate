import 'package:flutter/material.dart';
import 'package:matricmate/features/authentication/controllers/onboarding/onboardint_controller.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class OnBoaridngNavigation extends StatelessWidget {
  const OnBoaridngNavigation({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = OnboardintController.instance;
    bool dark = AppHelperFuntions.isDark(context);
    return Positioned(
      bottom: 30,
      left: 20,
      child: SmoothPageIndicator(
        count: 3,
        controller: controller.pageController,
        onDotClicked: controller.dotNavigationClick,
        effect: ExpandingDotsEffect(
          activeDotColor: AppColors.primary,
          dotHeight: 6,
          dotColor: dark ? AppColors.darkGrey : AppColors.darkerGrey,
        ),
      ),
    );
  }
}
