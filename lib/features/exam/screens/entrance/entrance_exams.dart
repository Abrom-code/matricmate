import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:matricmate/common/widgets/appbar/appbar.dart';
import 'package:matricmate/common/widgets/exam/premium_bottom_sheet.dart';
import 'package:matricmate/common/widgets/loaders/circular_loading.dart';
import 'package:matricmate/features/exam/controllers/entrance_exams_controller.dart';
import 'package:matricmate/features/exam/controllers/exam_selection_controller.dart';
import 'package:matricmate/features/exam/models/test_model.dart';
import 'package:matricmate/features/exam/screens/ready/ready.dart';
import 'package:matricmate/features/exam/screens/tests_list/widgets/test_tile.dart';
import 'package:matricmate/features/personalization/controllers/user_controller.dart';
import 'package:matricmate/routes/app_routes.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              subject,
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 18.5,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
              ),
            ),
            const Text(
              'Entrance & Model Exams',
              style: TextStyle(
                color: Color(0xFFD1FAE5),
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            height: 38,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: AppColors.white.withValues(alpha: 0.12),
                width: 1,
              ),
            ),
            child: TabBar(
              controller: tabCtrl.tabController,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: AppColors.white.withValues(alpha: 0.22),
                border: Border.all(
                  color: AppColors.white.withValues(alpha: 0.35),
                  width: 1,
                ),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: AppColors.white,
              unselectedLabelColor: AppColors.white.withValues(alpha: 0.70),
              labelPadding: EdgeInsets.zero,
              tabs: tabCtrl.tabs.map((t) {
                return Tab(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Text(
                        t['label'],
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
      body: Obx(() {
        if (ctrl.isLoading.value) {
          return const AppCircularLoading(title: 'Loading exams...');
        }

        return TabBarView(
          controller: tabCtrl.tabController,
          children: [
            _ExamList(
              tests: ctrl.entranceTests,
              controller: ctrl,
              label: 'Entrance',
            ),
            _ExamList(
              tests: ctrl.modelTests,
              controller: ctrl,
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
  final EntranceExamsController controller;
  final String label;

  @override
  Widget build(BuildContext context) {
    final dark = AppHelperFunctions.isDark(context);

    if (tests.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.primary
                      .withValues(alpha: dark ? 0.15 : 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.assignment_outlined,
                  size: 40,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'No $label Exams Available',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Check back soon or sync on the home screen to refresh.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12.5,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final isLandscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;

    final list = ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 40),
      itemCount: tests.length + 1,
      itemBuilder: (context, index) {
        // Top count header
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12, left: 2, right: 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$label Papers',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: dark ? AppColors.darkGrey : AppColors.textSecondary,
                    letterSpacing: 0.2,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 3.5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(
                      alpha: dark ? 0.2 : 0.1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${tests.length} tests available',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        final test = tests[index - 1];
        final hasQn = controller.testHasQuestions[test.id] ?? false;
        final testIndex = index - 1;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Obx(() {
            final isInactive = UserController.instance.user.value.isInactive;
            final isPending = UserController.instance.user.value.isPending;
            final isActive = UserController.instance.user.value.isActive;

            // Subscribe to testResults so tile rebuilds reactively.
            final _ = controller.testResults[test.id];

            final canAccess =
                isActive || ((isInactive || isPending) && testIndex < 2);

            return TestTile(
              icon: canAccess ? Iconsax.message_question_copy : Icons.lock,
              iconColor: canAccess ? AppColors.primary : Colors.amber,
              currentStep: controller.getCurrentStep(test.id),
              maxStep: controller.getMaxStep(test.id),
              correctAnswers: controller.getCorrectAnswers(test.id),
              isInProgress: controller.isInProgress(test.id),
              testName: test.title,
              description: test.description,
              questionCount:
                  controller.testQuestionCounts[test.id] ?? test.questionCount,
              timeMinutes: test.time,
              isNew: test.isNew,
              onTap: () {
                if (isInactive && testIndex >= 2) {
                  Get.bottomSheet(
                    const PremiumBottomSheet(),
                    isScrollControlled: true,
                  );
                  return;
                }
                if (isPending && testIndex >= 2) {
                  Get.toNamed(Routes.paymentVerification);
                  return;
                }
                if (!hasQn) {
                  ToastHelper.info('No questions added yet!');
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
                    description: test.description,
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
