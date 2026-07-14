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
import 'package:matricmate/utils/constants/sizes.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

class QuestionScreen extends StatelessWidget {
  const QuestionScreen({super.key});

  void _openSheet(BuildContext context, QuestionController ctrl) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => QuestionNavigatorSheet(controller: ctrl),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<QuestionController>();
    final bookmarkController = Get.find<BookmarkController>();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (controller.exitDialogOpen) return; // dialog already showing
        controller.pauseTimer();
        AppHelperFunctions.showAppDialog(
          context,
          controller.isExamMode ? 'Pause & Exit?' : 'Exit Practice?',
          'Your progress will be saved. You can resume later.',
          () {
            Navigator.pop(context); // dismiss dialog
            Navigator.pop(context); // pop question screen
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

          appBar: Appbar(
            leadingIcon: controller.isExamMode
                ? Icons.pause_rounded
                : Icons.close_rounded,
            leadingIconColor: AppColors.error,
            leadingOnPressed: () {
              if (controller.exitDialogOpen) return;
              controller.pauseTimer();
              AppHelperFunctions.showAppDialog(
                context,
                controller.isExamMode ? 'Pause & Exit?' : 'Exit Practice?',
                'Your progress will be saved. You can resume later.',
                () {
                  Navigator.pop(context); // dismiss dialog
                  Navigator.pop(context); // pop question screen
                },
                onCancel: () => controller.resumeTimer(),
              );
            },
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
                  // Counter text is driven by currentIndex which the parent
                  // Obx already subscribes to — no inner Obx needed here.
                  final counterText = hasData
                      ? '${controller.currentIndex.value + 1} of ${controller.testQuestions.length}'
                      : 'Loading...';

                  if (!controller.isTimed) {
                    return Text(
                      counterText,
                      style: Theme.of(ctx).textTheme.titleMedium!.copyWith(
                            color: AppColors.primary,
                          ),
                    );
                  }

                  // Timed: wrap only the timer-sensitive part in its own Obx
                  // so the title updates every second without rebuilding the
                  // whole scaffold.
                  return Obx(() => Text(
                        '$counterText (${controller.formattedTime(controller.remainingSeconds.value)})',
                        style: Theme.of(ctx).textTheme.titleMedium!.copyWith(
                              color: controller.remainingSeconds.value < 300
                                  ? Colors.amber
                                  : AppColors.primary,
                            ),
                      ));
                }

                final timerColor = controller.remainingSeconds.value < 300
                    ? Colors.amber
                    : AppColors.primary;

                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        sectionTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(ctx)
                            .textTheme
                            .titleMedium!
                            .copyWith(color: AppColors.primary),
                      ),
                    ),
                    if (controller.isTimed) ...[
                      const SizedBox(width: AppSizes.xs),
                      Obx(() => Text(
                            '(${controller.formattedTime(controller.remainingSeconds.value)})',
                            style: Theme.of(ctx)
                                .textTheme
                                .labelMedium!
                                .copyWith(
                                  color: timerColor,
                                  fontWeight: FontWeight.w600,
                                ),
                          )),
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
                  return IconButton(
                    onPressed: isSaved
                        ? () =>
                            bookmarkController.removeFromBookmark(currentQ.id)
                        : () => bookmarkController.addToBookmark(currentQ.id),
                    icon: Icon(
                      isSaved
                          ? Iconsax.archive_minus
                          : Iconsax.archive_add_copy,
                      color: AppColors.primary,
                    ),
                  );
                }),
            ],
            backgroundColor: Colors.transparent,
          ),

          body: (controller.isLoading.value || controller.isPassageLoading.value)
              ? const AppCircularLoading()
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (currentQ?.passageId != null)
                        PassageContainer(controller: controller),
                      if (currentQ != null)
                        QuesitonSection(question: currentQ),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
        );
      }),
    );
  }
}
