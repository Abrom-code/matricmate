import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matricmate/bindings/question_binding.dart';
import 'package:matricmate/common/widgets/appbar/appbar.dart';
import 'package:matricmate/common/widgets/tiles/test_tile.dart';
import 'package:matricmate/features/exam/controllers/test_controller.dart';
import 'package:matricmate/features/exam/screens/premium/widgets/premium_bottom_sheet.dart';
import 'package:matricmate/features/exam/screens/question/question.dart';
import 'package:matricmate/features/personalization/controller/user_controller.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/constants/sizes.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';
import 'package:matricmate/utils/helpers/toast_helper.dart';

class GradeTestsPage extends GetView<TestController> {
  const GradeTestsPage({super.key, required this.grade, required this.subject});

  final int grade;
  final String subject;

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.loadGradeTests(grade);
    });

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
          final tests = controller.singleGradeTests;

          if (tests.isEmpty) {
            return const Center(child: Text("No Tests Found"));
          }

          return ListView.builder(
            itemCount: tests.length,
            itemBuilder: (context, index) {
              final test = tests[index];

              final hasQn = controller.testHasQuestions[test.id] ?? false;
              final isActive =
                  index < 1 || UserController.instance.user.value.isActive;
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSizes.spaceBtwItems),
                child: Obx(
                  () => TestTile(
                    icon: isActive ? Icons.quiz : Icons.lock,
                    iconColor: isActive ? Colors.teal : Colors.amber,
                    currentStep: controller.getCurrentStep(test.id),
                    maxStep: controller.getMaxStep(test.id),
                    testName: test.title,
                    onTap: () {
                      if (!hasQn) {
                        if (!isActive) {
                          Get.bottomSheet(
                            const PremiumBottomSheet(),
                            isScrollControlled: true,
                          );
                          return;
                        }
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
                        () => Get.off(
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
        }),
      ),
    );
  }
}
