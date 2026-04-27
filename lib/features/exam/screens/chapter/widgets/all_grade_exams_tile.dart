import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matricmate/common/widgets/tiles/test_tile.dart';
import 'package:matricmate/features/exam/controllers/question_controller.dart';
import 'package:matricmate/features/exam/controllers/test_controller.dart';
import 'package:matricmate/features/exam/screens/premium/payment_verify.dart';
import 'package:matricmate/features/exam/screens/premium/widgets/premium_bottom_sheet.dart';
import 'package:matricmate/features/personalization/controller/user_controller.dart';
import 'package:matricmate/routes/app_routes.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';
import 'package:matricmate/utils/helpers/toast_helper.dart';

class AllGradeExamsTile extends StatelessWidget {
  const AllGradeExamsTile({super.key, required this.subjectId});
  final int subjectId;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<TestController>();
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
          final isInactive = UserController.instance.user.value.isInactive;
          final isPending = UserController.instance.user.value.isPending;

          return Obx(
            () => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: TestTile(
                icon: (isInactive || isPending) ? Icons.lock : Icons.quiz,
                iconColor: isInactive || isPending ? Colors.amber : Colors.teal,
                currentStep: controller.getCurrentStep(test.id),
                maxStep: controller.getMaxStep(test.id),
                testName: test.title,
                onTap: () {
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
                    () {
                      Get.toNamed(Routes.questions, arguments: test.id);
                      Get.delete<QuestionController>();
                    },
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
