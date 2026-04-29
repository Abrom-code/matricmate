import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matricmate/common/widgets/appbar/appbar.dart';
import 'package:matricmate/common/widgets/tiles/test_tile.dart';
import 'package:matricmate/features/exam/controllers/test_controller.dart';
import 'package:matricmate/features/exam/screens/premium/payment_verify.dart';
import 'package:matricmate/features/exam/screens/premium/widgets/premium_bottom_sheet.dart';
import 'package:matricmate/features/exam/screens/ready/ready.dart';
import 'package:matricmate/features/personalization/controller/user_controller.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/constants/sizes.dart';
import 'package:matricmate/utils/helpers/toast_helper.dart';

class GradeTestsPage extends GetView<TestController> {
  const GradeTestsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final grade = controller.grade;
    final subject = controller.title;

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
              final qnCount = test.questionCount;
              final time = test.time;

              return Padding(
                padding: const EdgeInsets.only(bottom: AppSizes.spaceBtwItems),
                child: Obx(() {
                  final isInactive =
                      UserController.instance.user.value.isInactive;
                  final isPending =
                      UserController.instance.user.value.isPending;
                  final isActive = UserController.instance.user.value.isActive;

                  final canAccess =
                      isActive || ((isInactive || isPending) && index < 1);
                  return TestTile(
                    icon: canAccess ? Icons.quiz : Icons.lock,
                    iconColor: canAccess ? Colors.teal : Colors.amber,
                    currentStep: controller.getCurrentStep(test.id),
                    maxStep: controller.getMaxStep(test.id),
                    testName: test.title,
                    onTap: () {
                      if (!hasQn) {
                        if (isInactive) {
                          Get.bottomSheet(
                            const PremiumBottomSheet(),
                            isScrollControlled: true,
                          );
                          return;
                        }
                        if (isPending) {
                          Get.to(() => const PaymentVerificationScreen());
                          return;
                        }
                        ToastHelper.info(
                          "No Quesions!",
                          "Quesions will be added soon!",
                        );
                        return;
                      }

                      Get.dialog(
                        ReadyDialog(
                          qnCount: qnCount,
                          time: time,
                          testId: test.id,
                        ),
                      );
                    },
                  );
                }),
              );
            },
          );
        }),
      ),
    );
  }
}
