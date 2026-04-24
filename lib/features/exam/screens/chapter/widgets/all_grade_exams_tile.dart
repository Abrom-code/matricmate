import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matricmate/bindings/question_binding.dart';
import 'package:matricmate/common/widgets/tiles/test_tile.dart';
import 'package:matricmate/features/exam/controllers/test_controller.dart';
import 'package:matricmate/features/exam/screens/premium/widgets/premium_bottom_sheet.dart';
import 'package:matricmate/features/exam/screens/question/question.dart';
import 'package:matricmate/features/personalization/controller/user_controller.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';
import 'package:matricmate/utils/helpers/toast_helper.dart';

class AllGradeExamsTile extends GetView<TestController> {
  const AllGradeExamsTile({super.key, required this.subjectId});
  final int subjectId;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final tests = controller.allGradeTests;

      // empty state
      if (tests.isEmpty) {
        return const Center(child: Text("No Tests Found"));
      }

      // scrollable (fix overflow)
      return ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: tests.length,
        itemBuilder: (context, index) {
          final test = tests[index];

          // use cached value only
          final hasQn = controller.testHasQuestions[test.id] ?? false;
          final isActive = UserController.instance.user.value.isActive;

          return Obx(
            () => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: TestTile(
                icon: isActive ? Icons.quiz : Icons.lock,
                iconColor: isActive ? Colors.teal : Colors.amber,
                currentStep: controller.getCurrentStep(test.id),
                maxStep: controller.getMaxStep(test.id),
                testName: test.title,
                onTap: () {
                  if (!isActive) {
                    Get.bottomSheet(
                      const PremiumBottomSheet(),
                      isScrollControlled: true,
                    );
                    return;
                  }
                  if (!hasQn) {
                    ToastHelper.info(
                      "No Quesions!",
                      "Quesions will be added soon!",
                    );
                    return;
                  }

                  AppHelperFuntions.showAppDialog(
                    context,
                    "Want to take a test?",
                    "You will be redirected to questions section.",
                    () => Get.to(
                      () => QuestionScreen(),
                      binding: QuestionBinding(),
                      arguments: test.id,
                    ),
                  );
                },
              ),
            ),
          );
        },
      );
    });
  }
}
