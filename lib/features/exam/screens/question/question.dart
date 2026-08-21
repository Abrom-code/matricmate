import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:matricmate/common/widgets/appbar/appbar.dart';
import 'package:matricmate/common/widgets/loaders/circular_loading.dart';
import 'package:matricmate/features/exam/controllers/bookmark_controller.dart';
import 'package:matricmate/features/exam/controllers/question_controller.dart';
import 'package:matricmate/features/exam/screens/question/widgets/normal_questions_section.dart';
import 'package:matricmate/features/exam/screens/question/widgets/passage_container.dart';
import 'package:matricmate/features/exam/screens/question/widgets/passage_layout_ctrl.dart';
import 'package:matricmate/features/exam/screens/question/widgets/progress_fab.dart';
import 'package:matricmate/features/exam/screens/question/widgets/question_navigator_sheet.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

class QuestionScreen extends StatefulWidget {
  const QuestionScreen({super.key});

  @override
  State<QuestionScreen> createState() => _QuestionScreenState();
}

class _QuestionScreenState extends State<QuestionScreen> {
  /// Outer scroll controller shared with PassageContainer.
  final ScrollController _scrollController = ScrollController();

  void _openSheet(BuildContext context, QuestionController ctrl) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => QuestionNavigatorSheet(controller: ctrl),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<QuestionController>();
    final bookmarkController = Get.find<BookmarkController>();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (controller.exitDialogOpen) return;
        controller.pauseTimer();
        AppHelperFunctions.showAppDialog(
          context,
          controller.isExamMode ? 'Pause & Exit?' : 'Exit Practice?',
          'Your progress will be saved. You can resume later.',
          () {
            Navigator.pop(context);
            Navigator.pop(context);
          },
          onCancel: () => controller.resumeTimer(),
        );
      },
      child: Obx(() {
        final bool hasData = controller.testQuestions.isNotEmpty;
        final currentQ = hasData
            ? controller.testQuestions[controller.currentIndex.value]
            : null;

        return Scaffold(
          floatingActionButton: hasData
              ? ProgressFab(
                  controller: controller,
                  onPressed: () => _openSheet(context, controller),
                )
              : null,

          appBar: AppBar(
            backgroundColor: AppColors.primary,
            elevation: 0,
            scrolledUnderElevation: 0,
            toolbarHeight: Appbar.toolbarHeight(context),
            leading: Padding(
              padding: const EdgeInsets.only(left: 4),
              child: IconButton(
                onPressed: () {
                  if (controller.exitDialogOpen) return;
                  controller.pauseTimer();
                  AppHelperFunctions.showAppDialog(
                    context,
                    controller.isExamMode ? 'Pause & Exit?' : 'Exit Practice?',
                    'Your progress will be saved. You can resume later.',
                    () {
                      Navigator.pop(context);
                      Navigator.pop(context);
                    },
                    onCancel: () => controller.resumeTimer(),
                  );
                },
                tooltip: controller.isExamMode ? 'Pause' : 'Exit',
                icon: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      controller.isExamMode
                          ? Icons.pause_rounded
                          : Icons.close_rounded,
                      size: 18,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ),
            ),
            title: Builder(
              builder: (ctx) {
                final hasPassage = currentQ?.passageId != null;
                final sectionTitle =
                    (currentQ?.sectionTitle?.trim().isNotEmpty == true)
                    ? currentQ!.sectionTitle!.trim()
                    : null;
                if (hasPassage) {
                  return PassageLayoutCtrl(controller: controller);
                }

                if (sectionTitle == null) {
                  final counterText = hasData
                      ? 'Question ${controller.currentIndex.value + 1} of ${controller.testQuestions.length}'
                      : 'Loading...';

                  if (!controller.isTimed) {
                    return Text(
                      counterText,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 16.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    );
                  }

                  return Obx(() {
                    final remaining = controller.remainingSeconds.value;
                    final isLowTime = remaining < 300;
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${controller.currentIndex.value + 1}/${controller.testQuestions.length}',
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: isLowTime
                                ? Colors.red.withValues(alpha: 0.3)
                                : AppColors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isLowTime
                                  ? Colors.redAccent
                                  : AppColors.white.withValues(alpha: 0.25),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.timer_outlined,
                                size: 13,
                                color: isLowTime
                                    ? Colors.amberAccent
                                    : const Color(0xFFD1FAE5),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                controller.formattedTime(remaining),
                                style: TextStyle(
                                  color: isLowTime
                                      ? Colors.amberAccent
                                      : const Color(0xFFD1FAE5),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  });
                }

                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        sectionTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (controller.isTimed) ...[
                      const SizedBox(width: 8),
                      Obx(() {
                        final remaining = controller.remainingSeconds.value;
                        final isLowTime = remaining < 300;
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2.5,
                          ),
                          decoration: BoxDecoration(
                            color: isLowTime
                                ? Colors.red.withValues(alpha: 0.3)
                                : AppColors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            controller.formattedTime(remaining),
                            style: TextStyle(
                              color: isLowTime
                                  ? Colors.amberAccent
                                  : const Color(0xFFD1FAE5),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        );
                      }),
                    ],
                  ],
                );
              },
            ),
            centerTitle: true,
            actions: [
              if (currentQ != null)
                Obx(() {
                  final isSaved = controller.isBookmarked(currentQ.id);
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: IconButton(
                      onPressed: isSaved
                          ? () => bookmarkController.removeFromBookmark(
                                currentQ.id,
                              )
                          : () => bookmarkController.addToBookmark(currentQ.id),
                      tooltip: isSaved ? 'Remove bookmark' : 'Bookmark',
                      icon: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: isSaved
                              ? Colors.amber.withValues(alpha: 0.25)
                              : AppColors.white.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Icon(
                            isSaved
                                ? Iconsax.archive_minus
                                : Iconsax.archive_add_copy,
                            color: isSaved ? Colors.amber : AppColors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(3),
              child: Obx(() {
                final total = controller.testQuestions.length;
                final done = controller.isExamMode
                    ? controller.selectedAnswers.length
                    : controller.isChecked.values.where((v) => v).length;
                final progress = total == 0 ? 0.0 : (done / total).clamp(0.0, 1.0);
                return LinearProgressIndicator(
                  value: progress,
                  minHeight: 3,
                  backgroundColor: AppColors.white.withValues(alpha: 0.15),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFF34D399),
                  ),
                );
              }),
            ),
          ),

          body:
              (controller.isLoading.value || controller.isPassageLoading.value)
              ? const AppCircularLoading()
              : SingleChildScrollView(
                  controller: _scrollController,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (currentQ?.passageId != null)
                        PassageContainer(
                          controller: controller,
                          outerScrollController: _scrollController,
                        ),
                      if (currentQ != null)
                        ExamQuestionSection(question: currentQ),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
        );
      }),
    );
  }
}
