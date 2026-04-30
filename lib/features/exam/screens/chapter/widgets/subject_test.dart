import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matricmate/features/exam/screens/tests_list/widgets/test_tile.dart';
import 'package:matricmate/features/exam/controllers/test_controller.dart';
import 'package:matricmate/features/exam/screens/premium/payment_verify.dart';
import 'package:matricmate/features/exam/screens/premium/widgets/premium_bottom_sheet.dart';
import 'package:matricmate/features/exam/screens/ready/ready.dart';
import 'package:matricmate/features/personalization/controller/user_controller.dart';
import 'package:matricmate/utils/helpers/toast_helper.dart';

class AllGradeExamsTile extends StatelessWidget {
  const AllGradeExamsTile({
    super.key,
    required this.subjectId,
    required this.subject,
  });
  final int subjectId;
  final String subject;

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

          final hasQn = controller.testHasQuestions[test.id] ?? false;
          final qnCount = test.questionCount;
          final time = test.time;

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

                  Get.dialog(
                    ReadyDialog(qnCount: qnCount, time: time, testId: test.id),
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
