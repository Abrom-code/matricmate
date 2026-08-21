import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:matricmate/common/widgets/appbar/appbar.dart';
import 'package:matricmate/common/widgets/loaders/circular_loading.dart';
import 'package:matricmate/features/exam/controllers/entrance_exams_controller.dart';
import 'package:matricmate/features/exam/controllers/exam_selection_controller.dart';
import 'package:matricmate/features/exam/models/test_model.dart';
import 'package:matricmate/common/widgets/exam/premium_bottom_sheet.dart';
import 'package:matricmate/features/exam/screens/ready/ready.dart';
import 'package:matricmate/features/exam/screens/tests_list/widgets/test_tile.dart';
import 'package:matricmate/features/personalization/controllers/user_controller.dart';
import 'package:matricmate/routes/app_routes.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/constants/sizes.dart';
import 'package:matricmate/utils/helpers/toast_helper.dart';

class EntranceExamsScreen extends StatefulWidget {
  const EntranceExamsScreen({super.key});

  @override
  State<EntranceExamsScreen> createState() => _EntranceExamsScreenState();
}

class _EntranceExamsScreenState extends State<EntranceExamsScreen>
    with RouteAware {
  EntranceExamsController get ctrl => EntranceExamsController.instance;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    appRouteObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    appRouteObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    final all = [...ctrl.entranceTests, ...ctrl.modelTests];
    if (all.isNotEmpty) ctrl.loadTestResults(all);
  }

  @override
  Widget build(BuildContext context) {
    final tabCtrl = ExamSelectionController.instance;
    final subject = ctrl.subjectName;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: Appbar.toolbarHeight(context),
        leading: Padding(
          padding: const EdgeInsets.only(left: 4),
          child: IconButton(
            onPressed: Get.back,
            tooltip: 'Back',
            icon: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 16,
                  color: AppColors.white,
                ),
              ),
            ),
          ),
        ),
        title: Text(
          subject,
          style: const TextStyle(
            color: AppColors.white,
            fontSize: 18.5,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
          ),
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
        if (ctrl.isLoading.value) {
          return const AppCircularLoading(title: 'Loading...');
        }

        return TabBarView(
          controller: tabCtrl.tabController,
          children: [
            _ExamList(
              tests: ctrl.entranceTests,
              controller: ctrl,
              label: 'Entrance',
            ),
            _ExamList(tests: ctrl.modelTests, controller: ctrl, label: 'Model'),
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
  final EntranceExamsController controller;
  final String label;

  @override
  Widget build(BuildContext context) {
    if (tests.isEmpty) {
      return Center(child: Text('No $label Exams Found'));
    }

    final isLandscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;

    final list = ListView.builder(
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

            // Subscribe to testResults so tile rebuilds reactively.
            final _ = controller.testResults[test.id];

            final canAccess =
                isActive || ((isInactive || isPending) && index < 2);

            return TestTile(
              icon: canAccess ? Iconsax.message_question_copy : Icons.lock,
              iconColor: canAccess ? AppColors.primary : Colors.amber,
              currentStep: controller.getCurrentStep(test.id),
              maxStep: controller.getMaxStep(test.id),
              correctAnswers: controller.getCorrectAnswers(test.id),
              isInProgress: controller.isInProgress(test.id),
              testName: test.title,
              questionCount:
                  controller.testQuestionCounts[test.id] ?? test.questionCount,
              timeMinutes: test.time,
              isNew: test.isNew,
              onTap: () {
                if (isInactive && index >= 2) {
                  Get.bottomSheet(
                    const PremiumBottomSheet(),
                    isScrollControlled: true,
                  );
                  return;
                }
                if (isPending && index >= 2) {
                  Get.toNamed(Routes.paymentVerification);
                  return;
                }
                if (!hasQn) {
                  ToastHelper.info('No questions added!');
                  return;
                }
                Get.dialog(
                  ReadyDialog(
                    qnCount:
                        controller.testQuestionCounts[test.id] ??
                        test.questionCount,
                    time: test.time,
                    testId: test.id,
                    id: 2,
                    examTitle: test.title,
                    draft: controller.isInProgress(test.id)
                        ? controller.testResults[test.id]
                        : null,
                  ),
                );
              },
            );
          }),
        );
      },
    );

    if (!isLandscape) return list;

    // Landscape: constrain width so tiles don't stretch wall-to-wall.
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: list,
      ),
    );
  }
}
