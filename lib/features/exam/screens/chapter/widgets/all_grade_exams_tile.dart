import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matricmate/common/widgets/tiles/test_tile.dart';
import 'package:matricmate/features/exam/controllers/test_controller.dart';
import 'package:matricmate/features/exam/screens/question/question.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

class AllGradeExamsTile extends GetView<TestController> {
  const AllGradeExamsTile({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.allGradeTests.isEmpty) {
        return Text("No Qn Found", textAlign: TextAlign.center);
      }

      return Column(
        children: [
          ...controller.allGradeTests.map((test) {
            return TestTile(
              testName: test.title,
              onTap: () async {
                final testId = test.id;

                final hasQn =
                    controller.testHasQuestions[testId] ??
                    await TestController.instance.hasQuestions(test.id);

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
                  () => Get.off(
                    () => QuestionScreen(
                      testId: testId,
                      title: test.title,
                      type: test.type,
                      subjectId: test.subjectId,
                    ),
                    arguments: testId,
                  ),
                );
              },
            );
          }),
        ],
      );
    });
  }
}
