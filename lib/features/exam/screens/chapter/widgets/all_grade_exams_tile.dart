import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matricmate/bindings/question_binding.dart';
import 'package:matricmate/common/widgets/tiles/test_tile.dart';
import 'package:matricmate/features/exam/controllers/test_controller.dart';
import 'package:matricmate/features/exam/screens/question/question.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

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

          return Obx(
            () => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: TestTile(
                currentStep: controller.getCurrentStep(test.id),
                maxStep: controller.getMaxStep(test.id),
                testName: test.title,
                onTap: () {
                  if (!hasQn) {
                    AppHelperFuntions.showAlert(
                      "No Questions",
                      "This test has no questions",
                    );
                    return;
                  }

                  AppHelperFuntions.showAppDialog(
                    context,
                    "Want to take a test?",
                    "You will be redirected to questions section.",
                    () => Get.to(
                      () => QuestionScreen(test: test),
                      binding: QuestionBinding(),
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
