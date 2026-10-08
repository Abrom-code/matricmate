import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matricmate/common/widgets/exam/explanation_box.dart';
import 'package:matricmate/common/widgets/loaders/circular_loading.dart';
import 'package:matricmate/features/exam/controllers/question_controller.dart';
import 'package:matricmate/features/exam/models/question_model.dart';
import 'package:matricmate/features/exam/screens/question/widgets/choice_button.dart';
import 'package:matricmate/features/exam/screens/question/widgets/image_section.dart';
import 'package:matricmate/features/exam/screens/question/widgets/question_section.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/constants/sizes.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

class ExamQuestionSection extends GetView<QuestionController> {
  const ExamQuestionSection({super.key, required this.question});
  final QuestionModel question;

  @override
  Widget build(BuildContext context) {
    final dark = AppHelperFunctions.isDark(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.defaultSpace,
        AppSizes.defaultSpace / 2,
        AppSizes.defaultSpace,
        AppSizes.defaultSpace,
      ),
      child: Obx(() {
        if (controller.testQuestions.isEmpty) {
          return const Center(child: AppPulsingDots());
        }

        final q = controller.testQuestions[controller.currentIndex.value];
        final examMode = controller.isExamMode;

        final isChecked = controller.isAnswerChecked(q.id);
        final selectedIndex = controller.getSelectedAnswer(q.id);
        final isLast =
            controller.currentIndex.value ==
            controller.testQuestions.length - 1;

        final canSkip = examMode
            ? selectedIndex == null
            : !isChecked && !isLast;

        final isLandscape =
            MediaQuery.orientationOf(context) == Orientation.landscape;

        // ── Options column (shared between portrait and landscape) ─────────
        final Widget optionsColumn = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Options
            ...q.options.asMap().entries.map((entry) {
              final index = entry.key;
              final option = entry.value;
              final showChecked = controller.adminInspectorMode.value
                  ? true
                  : (examMode ? false : isChecked);
              final activeSelectedIndex = controller.adminInspectorMode.value
                  ? q.correctOptionIndex
                  : (selectedIndex ?? -1);

              return ChoiceButton(
                selectedIndex: activeSelectedIndex,
                isChecked: showChecked,
                optionTxt: option,
                index: index,
                questionId: q.id,
                correctIndex: q.correctOptionIndex,
                onTap: examMode
                    ? () => controller.selectAnswer(q.id, index)
                    : () {
                        if (!isChecked) {
                          controller.selectAnswer(q.id, index);
                          controller.checkAnswer(q.id);
                        }
                      },
              );
            }),

            // Explanation — practice mode or admin inspector mode
            if ((isChecked && !examMode) || controller.adminInspectorMode.value) ...[
              AppExplanationBox(
                explanationEn: q.explanationEn,
                explanationAm: q.explanationAm,
                explanationImageUrl: q.explanationImageUrl,
                expanded: controller.adminInspectorMode.value || controller.isExplanationExpanded.value,
                onToggle: () => controller.isExplanationExpanded.value =
                    !controller.isExplanationExpanded.value,
                languageSelected: controller.languageSelected,
                onLanguageChange: (v) => controller.languageSelected.value = v,
              ),
              const SizedBox(height: AppSizes.spaceBtwItems),
            ] else
              const SizedBox(height: AppSizes.xs),

            // Nav buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(
                        color: dark
                            ? AppColors.darkBorder
                            : AppColors.borderPrimary,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: controller.currentIndex.value > 0
                        ? controller.previousQuestion
                        : null,
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 14,
                    ),
                    label: const Text(
                      'Prev',
                      style: TextStyle(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: canSkip
                      ? OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            foregroundColor: dark
                                ? AppColors.darkGrey
                                : AppColors.textSecondary,
                            side: BorderSide(
                              color: dark
                                  ? AppColors.darkBorder
                                  : AppColors.borderPrimary,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: controller.isSubmitting.value
                              ? null
                              : examMode
                              ? () async {
                                  if (isLast) {
                                    await controller.submitExam();
                                  } else {
                                    controller.skipQuestion();
                                  }
                                }
                              : controller.skipQuestion,
                          icon: controller.isSubmitting.value && isLast
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Icon(
                                  examMode && isLast
                                      ? Icons.flag_rounded
                                      : Icons.skip_next_rounded,
                                  size: 16,
                                ),
                          label: Text(
                            examMode && isLast
                                ? (controller.isSubmitting.value ? 'Submitting…' : 'Finish')
                                : 'Skip',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        )
                      : ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: controller.isSubmitting.value
                              ? null
                              : examMode
                              ? () async {
                                  if (isLast) {
                                    await controller.submitExam();
                                  } else {
                                    controller.nextQuestion();
                                  }
                                }
                              : !isChecked
                              ? null
                              : () async {
                                  if (isLast) {
                                    await controller.submitExam();
                                  } else {
                                    controller.nextQuestion();
                                  }
                                },
                          icon: controller.isSubmitting.value && isLast
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.white,
                                  ),
                                )
                              : Icon(
                                  isLast
                                      ? Icons.flag_rounded
                                      : Icons.arrow_forward_ios_rounded,
                                  size: 15,
                                ),
                          label: Text(
                            isLast
                                ? (controller.isSubmitting.value ? 'Submitting…' : 'Finish')
                                : 'Next',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                ),
              ],
            ),
          ],
        );

        // ── Portrait: single scrollable column ────────────────────────────
        if (!isLandscape) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              QuestionSection(
                qnNumber: q.questionOrder,
                examQn: q.questionText,
              ),
              const SizedBox(height: AppSizes.spaceBtwItems),
              if (q.imageUrl != null) ImageSection(key: ValueKey(q.imageUrl), imgUrl: q.imageUrl),
              if (q.imageUrl != null)
                const SizedBox(height: AppSizes.spaceBtwItems),
              optionsColumn,
            ],
          );
        }

        // ── Landscape: question + image on left, options + buttons on right ─
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left: question text + image (independently scrollable)
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    QuestionSection(
                      qnNumber: q.questionOrder,
                      examQn: q.questionText,
                    ),
                    if (q.imageUrl != null) ...[
                      const SizedBox(height: AppSizes.spaceBtwItems),
                      ImageSection(key: ValueKey(q.imageUrl), imgUrl: q.imageUrl),
                    ],
                    const SizedBox(height: AppSizes.spaceBtwItems),
                  ],
                ),
              ),
            ),

            const SizedBox(width: AppSizes.defaultSpace),

            // Right: options + nav buttons (independently scrollable)
            Expanded(child: SingleChildScrollView(child: optionsColumn)),
          ],
        );
      }),
    );
  }
}
