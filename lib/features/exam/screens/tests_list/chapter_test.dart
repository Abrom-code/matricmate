import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:matricmate/common/widgets/appbar/appbar.dart';
import 'package:matricmate/common/widgets/loaders/circular_loading.dart';
import 'package:matricmate/features/exam/controllers/chapter_test_controller.dart';
import 'package:matricmate/features/exam/screens/premium/widgets/premium_bottom_sheet.dart';
import 'package:matricmate/features/exam/screens/ready/ready.dart';
import 'package:matricmate/features/exam/screens/tests_list/widgets/test_tile.dart';
import 'package:matricmate/features/personalization/controllers/user_controller.dart';
import 'package:matricmate/routes/app_routes.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/constants/sizes.dart';
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
    final subject = ctrl.title;
    final chapter = ctrl.chapter;

    return Scaffold(
      appBar: Appbar(
        showBackArrow: true,
        title: Text(
          '$subject ${chapter.isNotEmpty ? '- $chapter' : ''}'.toUpperCase(),
          style: Theme.of(context).textTheme.titleSmall!.apply(
                color: AppColors.white,
              ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSizes.defaultSpace),
        child: Obx(() {
          if (ctrl.isLoading.value) {
            return const AppCircularLoading(title: 'Loading');
          }

          final tests = ctrl.chapterTest;

          if (tests.isEmpty) {
            return const Center(child: Text('No Tests Found'));
          }

          return ListView.builder(
            itemCount: tests.length,
            itemBuilder: (context, index) {
              final test = tests[index];
              final hasQn = ctrl.testHasQuestions[test.id] ?? false;
              final qnCount =
                  ctrl.testQuestionCounts[test.id] ?? test.questionCount;
              final time = test.time;

              return Padding(
                padding:
                    const EdgeInsets.only(bottom: AppSizes.spaceBtwItems),
                child: Obx(() {
                  final isInactive =
                      UserController.instance.user.value.isInactive;
                  final isPending =
                      UserController.instance.user.value.isPending;
                  final isActive =
                      UserController.instance.user.value.isActive;

                  // Subscribe to testResults so tile rebuilds when results
                  // load or change.
                  final _ = ctrl.testResults[test.id];

                  final canAccess =
                      isActive || ((isInactive || isPending) && index < 3);

                  return TestTile(
                    testName: test.title,
                    icon: canAccess
                        ? Iconsax.message_question_copy
                        : Icons.lock,
                    iconColor:
                        canAccess ? AppColors.primary : Colors.amber,
                    currentStep: ctrl.getCurrentStep(test.id),
                    maxStep: ctrl.getMaxStep(test.id),
                    correctAnswers: ctrl.getCorrectAnswers(test.id),
                    isInProgress: ctrl.isInProgress(test.id),
                    questionCount: qnCount,
                    timeMinutes: time,
                    onTap: () {
                      if (isInactive && index >= 3) {
                        Get.bottomSheet(const PremiumBottomSheet(),
                            isScrollControlled: true);
                        return;
                      }
                      if (isPending && index >= 3) {
                        Get.toNamed(Routes.paymentVerification);
                        return;
                      }
                      if (!hasQn) {
                        ToastHelper.info('Has no questions');
                        return;
                      }
                      Get.dialog(ReadyDialog(
                        qnCount: qnCount,
                        time: time,
                        testId: test.id,
                        id: 1,
                        draft: ctrl.isInProgress(test.id)
                            ? ctrl.testResults[test.id]
                            : null,
                      ));
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
