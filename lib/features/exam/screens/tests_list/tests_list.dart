import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matricmate/common/widgets/appbar/appbar.dart';
import 'package:matricmate/common/widgets/loaders/circular_loading.dart';
import 'package:matricmate/common/widgets/tiles/test_tile.dart';
import 'package:matricmate/features/exam/controllers/test_controller.dart';
import 'package:matricmate/features/exam/screens/premium/payment_verify.dart';
import 'package:matricmate/features/exam/screens/premium/widgets/premium_bottom_sheet.dart';
import 'package:matricmate/features/personalization/controller/user_controller.dart';
import 'package:matricmate/routes/app_routes.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/constants/sizes.dart';
import 'package:matricmate/utils/helpers/toast_helper.dart';

class TestListScreen extends GetView<TestController> {
  const TestListScreen({super.key});

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
          '$subject - $chapter'.toUpperCase(),
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
              final point = test.point;
              final time = test.time;
              final title = '$subject: ${test.title}';

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
                        ToastHelper.info(
                          "No Questions",
                          "This test has no questions",
                        );
                        return;
                      }

                      Get.toNamed(
                        Routes.ready,
                        arguments: {
                          'test_id': test.id,
                          'point': point,
                          'time': time,
                          'qn_count': qnCount,
                          'title': title,
                        },
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
