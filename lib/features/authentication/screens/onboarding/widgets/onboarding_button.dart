import 'package:flutter/material.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';
import 'package:matricmate/features/authentication/controllers/onboarding/onboardint_controller.dart';
import 'package:matricmate/features/exam/controllers/subjects_controller.dart';

class OnBoardingButton extends StatelessWidget {
  const OnBoardingButton({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = OnboardintController.instance;
    final subjectLoadingController = SubjectsController.instance;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => controller.nextPage(),
        child: Obx(
          () => (subjectLoadingController.isLoading.value
              ? SizedBox(
                  height: 15,
                  width: 15,
                  child: CircularProgressIndicator(),
                )
              : Text(
                  controller.currentPageIndex.value == 2 ? "Sign In" : "Next",
                )),
        ),
      ),
    );
  }
}
