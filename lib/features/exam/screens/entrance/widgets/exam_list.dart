import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:matricmate/common/widgets/loaders/circular_loading.dart';
import 'package:matricmate/features/exam/controllers/entrance_exams_controller.dart';
import 'package:matricmate/features/exam/controllers/exam_selection_controller.dart';
import 'package:matricmate/features/exam/models/test_model.dart';
import 'package:matricmate/features/exam/screens/tests_list/widgets/test_tile.dart';
import 'package:matricmate/features/exam/screens/premium/payment_verify.dart';
import 'package:matricmate/features/exam/screens/premium/widgets/premium_bottom_sheet.dart';
import 'package:matricmate/features/exam/screens/ready/ready.dart';
import 'package:matricmate/features/personalization/controller/user_controller.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/constants/sizes.dart';
import 'package:matricmate/utils/helpers/toast_helper.dart';

class EntranceExams extends StatelessWidget {
  const EntranceExams({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = ExamsController.instance;
    final tabCtrl = ExamSelectionController.instance;
    final subject = controller.subjectName;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          onPressed: Get.back,
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.white),
        ),
        title: Text(
          subject,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall!.apply(color: AppColors.white),
        ),
        bottom: TabBar(
          controller: tabCtrl.tabController,
          tabAlignment: TabAlignment.fill,
          labelPadding: const EdgeInsets.symmetric(horizontal: 10),
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: AppColors.white,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 13,
            color: AppColors.white,
          ),
          indicatorColor: AppColors.white,
          dividerColor: Colors.transparent,
          tabs: tabCtrl.tabs.map((t) => Tab(text: t['label'])).toList(),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const AppCircularLoading(title: 'Loading...');
        }

        return TabBarView(
          controller: tabCtrl.tabController,
          children: [
            _ExamList(
              tests: controller.entranceTests,
              controller: controller,
              label: 'Entrance',
            ),
            _ExamList(
              tests: controller.modelTests,
              controller: controller,
              label: 'Model',
            ),
          ],
        );
      }),
    );
  }
}

// ── Private list widget ───────────────────────────────────────────────────────

class _ExamList extends StatelessWidget {
  const _ExamList({
    required this.tests,
    required this.controller,
    required this.label,
  });

  final List<TestModel> tests;
  final ExamsController controller;
  final String label;

  @override
  Widget build(BuildContext context) {
    if (tests.isEmpty) {
      return Center(child: Text('No $label Exams Found'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppSizes.defaultSpace),
      itemCount: tests.length,
      itemBuilder: (context, index) {
        final test = tests[index];
        final hasQn = controller.testHasQuestions[test.id] ?? false;

        return Padding(
          padding: const EdgeInsets.only(bottom: AppSizes.spaceBtwItems),
          child: Obx(() {
            final isInactive = UserController.instance.user.value.isInactive;
            final isPending = UserController.instance.user.value.isPending;
            final isActive = UserController.instance.user.value.isActive;

            return TestTile(
              icon: isActive ? Iconsax.message_question_copy : Icons.lock,
              iconColor: isActive ? AppColors.primary : Colors.amber,
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
                  ToastHelper.info('No questions added!');
                  return;
                }
                Get.dialog(
                  ReadyDialog(
                    qnCount: test.questionCount,
                    time: test.time,
                    testId: test.id,
                    id: 2,
                  ),
                );
              },
            );
          }),
        );
      },
    );
  }
}
