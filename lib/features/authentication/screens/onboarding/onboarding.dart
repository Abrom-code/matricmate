import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matricmate/features/authentication/controllers/onboarding/onboardint_controller.dart';
import 'package:matricmate/features/authentication/screens/onboarding/widgets/onboarding_button.dart';
import 'package:matricmate/features/authentication/screens/onboarding/widgets/onboarding_navigation.dart';
import 'package:matricmate/features/authentication/screens/onboarding/widgets/onboarding_page.dart';
import 'package:matricmate/features/authentication/screens/onboarding/widgets/onboarding_skip.dart';
import 'package:matricmate/utils/constants/image_string.dart';
import 'package:matricmate/utils/constants/sizes.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize controller using GetX
    final controller = Get.put(OnboardintController());

    return Scaffold(
      // This line will now correctly pick up Colors.black in Dark Mode
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Stack(
          children: [
            /// Horizontal Scrollable Pages
            PageView(
              controller: controller.pageController,
              onPageChanged: controller.updagePageIndicator,
              children: const [
                OnBoardingPane(
                  mainText: "Welcome to",
                  mainSubText: "MatricMate",
                  subText:
                      "Your ultimate companion to master matric exams with ease and confidence.",
                  onboardImage: AppImages.firstOnboardingImage,
                ),
                OnBoardingPane(
                  mainText: "Questions from",
                  mainSubText: "Grade 9 - 12",
                  subText:
                      "Access a vast collection of questions from Grade 9 to 12 and sharpen your skills.",
                  onboardImage: AppImages.secondOnboardingImage,
                ),
                OnBoardingPane(
                  mainText: "Track Progress and",
                  mainSubText: "Ace Exams",
                  subText:
                      "Monitor your learning journey, review weak areas, and prepare to excel in every exam.",
                  onboardImage: AppImages.thirdOnboardingImage,
                ),
              ],
            ),

            /// Skip Button
            const OnwardingSkip(),

            Positioned(
              bottom: 50,
              left: 20,
              right: 20,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  OnBoaridngNavigation(),
                  const SizedBox(height: AppSizes.spaceBtwSections),
                  OnBoardingButton(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
