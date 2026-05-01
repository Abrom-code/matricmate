import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matricmate/common/widgets/appbar/appbar.dart';
import 'package:matricmate/common/widgets/loaders/circular_loading.dart';
import 'package:matricmate/features/exam/screens/tests_list/widgets/test_tile.dart';
import 'package:matricmate/features/exam/controllers/chapter_test_controller.dart';
import 'package:matricmate/features/exam/screens/premium/payment_verify.dart';
import 'package:matricmate/features/exam/screens/premium/widgets/premium_bottom_sheet.dart';
import 'package:matricmate/features/exam/screens/ready/ready.dart';
import 'package:matricmate/features/personalization/controller/user_controller.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/constants/sizes.dart';
import 'package:matricmate/utils/helpers/toast_helper.dart';

class ChapterTestScreen extends GetView<ChapterTestController> {
  const ChapterTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final subject = controller.title;
    final chapter = controller.chapter;
    final chapterId = controller.chapterId;
    final grade = controller.grade;
    return Scaffold(
      appBar: Appbar(
        showBackArrow: true,
        title: Text(
          '$subject ${chapter.isNotEmpty ? '- $chapter' : ''}'.toUpperCase(),
          style: Theme.of(
            context,
          ).textTheme.titleSmall!.apply(color: AppColors.white),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSizes.defaultSpace),
        child: Obx(() {
          if (controller.isLoading.value)
            return AppCircularLoading(title: 'Loading');

          final tests = controller.getTestsByGradeAndChapter(
            grade.value,
            chapterId.value,
          );

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
                    testName: test.title,
                    icon: canAccess ? Icons.quiz : Icons.lock,
                    iconColor: canAccess ? Colors.teal : Colors.amber,
                    currentStep: controller.getCurrentStep(test.id),
                    maxStep: controller.getMaxStep(test.id),
                    onTap: () {
                      if (isInactive && index > 0) {
                        Get.bottomSheet(
                          const PremiumBottomSheet(),
                          isScrollControlled: true,
                        );
                        return;
                      }
                      if (isPending && index > 0) {
                        Get.to(() => const PaymentVerificationScreen());
                        return;
                      }
                      if (!hasQn) {
                        ToastHelper.info("Has no questions");
                        return;
                      }
                      Get.dialog(
                        ReadyDialog(
                          qnCount: qnCount,
                          time: time,
                          testId: test.id,
                          id: 1,
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
