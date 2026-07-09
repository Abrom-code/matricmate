import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:matricmate/common/widgets/appbar/appbar.dart';
import 'package:matricmate/common/widgets/exam/explanation_box.dart';
import 'package:matricmate/features/exam/controllers/bookmark_controller.dart';
import 'package:matricmate/features/exam/models/question_model.dart';
import 'package:matricmate/features/exam/screens/question/widgets/choice_button.dart';
import 'package:matricmate/features/exam/screens/question/widgets/image_section.dart';
import 'package:matricmate/features/exam/screens/question/widgets/question_section.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/constants/sizes.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

class BookmarkedQnContainer extends GetView<BookmarkController> {
  const BookmarkedQnContainer({super.key, required this.qn});
  final QuestionModel qn;

  @override
  Widget build(BuildContext context) {
    final dark = AppHelperFunctions.isDark(context);

    return Scaffold(
      appBar: Appbar(
        showBackArrow: true,
        title: Text(
          'Bookmarked Question',
          style: Theme.of(context).textTheme.headlineSmall!.apply(
                color: AppColors.white,
              ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.defaultSpace / 2),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSizes.defaultSpace / 1.3),
          decoration: BoxDecoration(
            color: dark
                ? AppColors.darkerGrey.withValues(alpha: 0.5)
                : AppColors.lightCard,
            borderRadius: BorderRadius.circular(AppSizes.md),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header: subject badge + correct answer indicator ──────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.md,
                      vertical: AppSizes.xs,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppSizes.lg),
                    ),
                    child: Text(
                      controller.subject(qn.subjectId).toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.md,
                      vertical: AppSizes.xs,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppSizes.lg),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Iconsax.tick_circle_copy,
                          color: Colors.green,
                          size: 14,
                        ),
                        SizedBox(width: AppSizes.xs),
                        Text(
                          'Answer shown',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const Divider(height: AppSizes.lg),

              // ── Passage section (collapsible) ─────────────────────────────
              if (qn.passageId != null)
                Obx(() {
                  final passage = controller.passages[qn.passageId];
                  final expanded =
                      controller.isPassageExpanded[qn.id] ?? false;

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
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelLarge!
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
                                    color: dark
                                        ? AppColors.grey
                                        : AppColors.darkerGrey,
                                  ),
                                ),
                        ),
                        const SizedBox(height: AppSizes.spaceBtwItems),
                      ],
                    ],
                  );
                }),

              // ── Question text ─────────────────────────────────────────────
              QuestionSection(
                qnNumber: qn.questionOrder,
                examQn: qn.questionText,
              ),
              const SizedBox(height: AppSizes.spaceBtwItems),

              // ── Image ─────────────────────────────────────────────────────
              if (qn.imageUrl != null) ImageSection(imgUrl: qn.imageUrl),
              if (qn.imageUrl != null)
                const SizedBox(height: AppSizes.spaceBtwItems),

              // ── Options (correct answer highlighted) ──────────────────────
              ...qn.options.asMap().entries.map((entry) {
                return ChoiceButton(
                  isChecked: true,
                  selectedIndex: qn.correctOptionIndex,
                  optionTxt: entry.value,
                  index: entry.key,
                  questionId: qn.id,
                  correctIndex: qn.correctOptionIndex,
                );
              }),

              // ── Explanation ───────────────────────────────────────────────
              Obx(() {
                final expanded = controller.isExpanded[qn.id] ?? false;
                return AppExplanationBox(
                  explanationEn: qn.explanationEn,
                  explanationAm: qn.explanationAm,
                  expanded: expanded,
                  onToggle: () => controller.toggleExpanded(qn.id),
                  languageSelected: controller.languageSelected,
                  onLanguageChange: (v) =>
                      controller.languageSelected.value = v,
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
