import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:matricmate/common/widgets/appbar/appbar.dart';
import 'package:matricmate/common/widgets/exam/premium_bottom_sheet.dart';
import 'package:matricmate/common/widgets/loaders/circular_loading.dart';
import 'package:matricmate/features/exam/controllers/chapter_test_controller.dart';
import 'package:matricmate/features/exam/screens/ready/ready.dart';
import 'package:matricmate/features/exam/screens/tests_list/widgets/test_tile.dart';
import 'package:matricmate/features/personalization/controllers/user_controller.dart';
import 'package:matricmate/routes/app_routes.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';
import 'package:matricmate/utils/helpers/toast_helper.dart';

class ChapterTestScreen extends StatefulWidget {
  const ChapterTestScreen({super.key});

  @override
  State<ChapterTestScreen> createState() => _ChapterTestScreenState();
}

class _ChapterTestScreenState extends State<ChapterTestScreen> with RouteAware {
  ChapterTestController get ctrl => ChapterTestController.instance;

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

  /// Fired when a route on top of this one is popped (user navigates back).
  @override
  void didPopNext() {
    final tests = ctrl.chapterTest;
    if (tests.isNotEmpty) ctrl.loadTestResults(tests);
  }

  @override
  Widget build(BuildContext context) {
    final subject = ctrl.title.value;
    final chapter = ctrl.chapter.value;
    final dark = AppHelperFunctions.isDark(context);

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
              chapter.isNotEmpty ? chapter : subject,
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 18.5,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Obx(
              () => Text(
                '$subject • ${ctrl.isCommon.value ? "Section Tests" : "Chapter Tests"}',
                style: const TextStyle(
                  color: Color(0xFFD1FAE5),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
      body: Obx(() {
        if (ctrl.isLoading.value) {
          return const AppCircularLoading(title: 'Loading tests...');
        }

        final tests = ctrl.chapterTest;

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
                      Icons.quiz_outlined,
                      size: 40,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No Tests Available Yet',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    ctrl.isCommon.value
                        ? 'Tests for this section are coming soon.'
                        : 'Tests for this chapter are coming soon.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12.5,
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
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
          itemCount: tests.length + 1,
          itemBuilder: (context, index) {
            // Header row with test count
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12, left: 2, right: 2),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      ctrl.isCommon.value ? 'Section Tests' : 'Chapter Tests',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: dark ? AppColors.darkGrey : AppColors.textSecondary,
                        letterSpacing: 0.2,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(
                          alpha: dark ? 0.2 : 0.1,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${tests.length} tests available',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            final test = tests[index - 1];
            final hasQn = ctrl.testHasQuestions[test.id] ?? false;
            final qnCount =
                ctrl.testQuestionCounts[test.id] ?? test.questionCount;
            final time = test.time;
            final testIndex = index - 1;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Obx(() {
                final isInactive =
                    UserController.instance.user.value.isInactive;
                final isPending =
                    UserController.instance.user.value.isPending;
                final isActive = UserController.instance.user.value.isActive;

                final _ = ctrl.testResults[test.id];

                final canAccess =
                    isActive || ((isInactive || isPending) && testIndex < 3);

                return TestTile(
                  testName: test.title,
                  description: test.description,
                  icon: canAccess
                      ? Iconsax.message_question_copy
                      : Icons.lock,
                  iconColor: canAccess ? AppColors.primary : Colors.amber,
                  currentStep: ctrl.getCurrentStep(test.id),
                  maxStep: ctrl.getMaxStep(test.id),
                  correctAnswers: ctrl.getCorrectAnswers(test.id),
                  isInProgress: ctrl.isInProgress(test.id),
                  questionCount: qnCount,
                  timeMinutes: time,
                  onTap: () {
                    if (isInactive && testIndex >= 3) {
                      Get.bottomSheet(
                        const PremiumBottomSheet(),
                        isScrollControlled: true,
                      );
                      return;
                    }
                    if (isPending && testIndex >= 3) {
                      Get.toNamed(Routes.paymentVerification);
                      return;
                    }
                    if (!hasQn) {
                      ToastHelper.info('No questions added yet!');
                      return;
                    }
                    Get.dialog(
                      ReadyDialog(
                        qnCount: qnCount,
                        time: time,
                        testId: test.id,
                        id: 1,
                        examTitle: test.title,
                        description: test.description,
                        draft: ctrl.isInProgress(test.id)
                            ? ctrl.testResults[test.id]
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
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: list,
          ),
        );
      }),
    );
  }
}
