import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matricmate/bindings/question_binding.dart';
import 'package:matricmate/common/widgets/appbar/appbar.dart';
import 'package:matricmate/common/widgets/tiles/test_tile.dart';
import 'package:matricmate/features/exam/controllers/test_controller.dart';
import 'package:matricmate/features/exam/screens/question/question.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/constants/sizes.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

class GradeTestsPage extends GetView<TestController> {
  const GradeTestsPage({super.key, required this.grade, required this.subject});
  final int grade;
  final String subject;

  @override
  Widget build(BuildContext context) {
    controller.loadGradeTests(grade);
    return Scaffold(
      appBar: Appbar(
        showBackArrow: true,
        title: Text(
          '$subject - Grade $grade',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall!.apply(color: AppColors.white),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSizes.defaultSpace),
        child: Obx(() {
          final selectedGrade = controller.singleGradeTests;
          if (selectedGrade.isEmpty) {
            return Text("No Qn Found", textAlign: TextAlign.center);
          }

          return Column(
            children: [
              ...selectedGrade.map((test) {
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
                        binding: QuestionBinding(),
                        arguments: testId,
                      ),
                    );
                  },
                );
              }),
            ],
          );
        }),
      ),
    );
  }
}
