import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:matricmate/common/widgets/exam/explanation_box.dart';
import 'package:matricmate/features/exam/controllers/review_controller.dart';
import 'package:matricmate/features/exam/models/question_model.dart';
import 'package:matricmate/features/exam/models/result_model.dart';
import 'package:matricmate/features/exam/screens/question/widgets/choice_button.dart';
import 'package:matricmate/features/exam/screens/question/widgets/image_section.dart';
import 'package:matricmate/features/exam/screens/question/widgets/question_section.dart';
import 'package:matricmate/features/exam/screens/result/widgets/correct_check_button.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/constants/sizes.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

class ReviewContainer extends GetView<ReviewController> {
  const ReviewContainer({super.key, required this.qn, required this.result});
  final QuestionModel qn;
  final ResultModel result;

  @override
  Widget build(BuildContext context) {
    final dark = AppHelperFunctions.isDark(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.defaultSpace / 1.3),
      decoration: BoxDecoration(
        color: dark
            ? AppColors.darkerGrey.withValues(alpha: 0.5)
            : const Color(0xFFe7eae7),
        borderRadius: BorderRadius.circular(AppSizes.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header: question number + result badge ──────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${qn.questionOrder} of ${result.testQuestions.length}',
                style: Theme.of(
                  context,
                ).textTheme.labelMedium!.apply(fontSizeDelta: 3),
              ),
              result.selectedAnswers[qn.id] == null
                  ? CorrectCheckButton(
                      color: dark ? AppColors.darkGrey : AppColors.darkerGrey,
                      icon: Iconsax.timer_1_copy,
                      text: 'Not Answered',
                    )
                  : result.selectedAnswers[qn.id] == qn.correctOptionIndex
                  ? const CorrectCheckButton()
                  : const CorrectCheckButton(
                      color: Colors.red,
                      icon: Iconsax.close_circle_copy,
                      text: 'Incorrect',
                    ),
            ],
          ),

          const Divider(height: AppSizes.lg),

          // ── Passage section (collapsible) ───────────────────────────────
          if (qn.passageId != null)
            Obx(() {
              final passage = controller.passages[qn.passageId];
              final expanded = controller.isPassageExpanded[qn.id] ?? false;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => controller.togglePassage(qn.id),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.md,
                        vertical: AppSizes.sm,
                      ),
                      decoration: BoxDecoration(
                        color: dark
                            ? AppColors.primary.withValues(alpha: 0.15)
                            : AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(AppSizes.sm),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.article_outlined,
                            color: AppColors.primary,
                            size: 16,
                          ),
                          const SizedBox(width: AppSizes.sm),
                          Expanded(
                            child: Text(
                              passage?.title != null &&
                                      passage!.title!.isNotEmpty
                                  ? passage.title!
                                  : 'Reading Passage',
                              style: Theme.of(context).textTheme.labelLarge!
                                  .copyWith(color: AppColors.primary),
                            ),
                          ),
                          Icon(
                            expanded
                                ? Icons.keyboard_arrow_up_rounded
                                : Icons.keyboard_arrow_down_rounded,
                            color: AppColors.primary,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (expanded) ...[
                    const SizedBox(height: AppSizes.sm),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSizes.md),
                      decoration: BoxDecoration(
                        color: dark
                            ? AppColors.dark.withValues(alpha: 0.6)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(AppSizes.sm),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.2),
                        ),
                      ),
                      child: passage == null
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(AppSizes.md),
                                child: CircularProgressIndicator(),
                              ),
                            )
                          : Text(
                              passage.content,
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.7,
                                color: dark ? AppColors.grey : Colors.black87,
                              ),
                            ),
                    ),
                    const SizedBox(height: AppSizes.spaceBtwItems),
                  ],
                ],
              );
            }),

          // ── Question text ───────────────────────────────────────────────
          QuestionSection(qnNumber: qn.questionOrder, examQn: qn.questionText),
          const SizedBox(height: AppSizes.spaceBtwItems),

          // ── Image ───────────────────────────────────────────────────────
          if (qn.imageUrl != null) ImageSection(imgUrl: qn.imageUrl),
          if (qn.imageUrl != null)
            const SizedBox(height: AppSizes.spaceBtwItems),

          // ── Options ─────────────────────────────────────────────────────
          ...qn.options.asMap().entries.map((entry) {
            return ChoiceButton(
              isChecked: true,
              selectedIndex: result.selectedAnswers[qn.id] ?? -1,
              optionTxt: entry.value,
              index: entry.key,
              questionId: qn.id,
              correctIndex: qn.correctOptionIndex,
            );
          }),

          const SizedBox(height: AppSizes.spaceBtwItems),

          // ── Explanation ─────────────────────────────────────────────────
          Obx(() {
            final expanded = controller.isExpanded[qn.id] ?? false;
            return AppExplanationBox(
              explanationEn: qn.explanationEn,
              explanationAm: qn.explanationAm,
              expanded: expanded,
              onToggle: () => controller.toggle(qn.id),
              languageSelected: controller.languageSelected,
              onLanguageChange: (v) => controller.languageSelected.value = v,
            );
          }),
        ],
      ),
    );
  }
}
