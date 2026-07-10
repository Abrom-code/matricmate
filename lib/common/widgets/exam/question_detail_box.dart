import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:matricmate/common/widgets/exam/explanation_box.dart';
import 'package:matricmate/common/widgets/loaders/circular_loading.dart';
import 'package:matricmate/features/exam/models/question_model.dart';
import 'package:matricmate/features/exam/screens/question/widgets/choice_button.dart';
import 'package:matricmate/features/exam/screens/question/widgets/image_section.dart';
import 'package:matricmate/features/exam/screens/question/widgets/question_section.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/constants/sizes.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';
import 'package:matricmate/utils/helpers/rich_text_parser.dart';

/// A reusable question detail card used on both the bookmark detail screen
/// and the exam review screen.
///
/// It renders:
///  - A configurable header row (slot for left and right widgets)
///  - Collapsible passage section (if the question has a passage)
///  - Question text via [QuestionSection]
///  - Optional image
///  - Choice buttons with correct/wrong highlighting
///  - Collapsible [AppExplanationBox] with EN/AM toggle
///
/// The caller is responsible for managing reactive state (isExpanded,
/// isPassageExpanded, passages, languageSelected) and passing simple
/// snapshots + callbacks down — keeping this widget stateless and reusable.
class QuestionDetailBox extends StatelessWidget {
  const QuestionDetailBox({
    super.key,
    required this.question,
    // ── Header ────────────────────────────────────────────────────────
    required this.headerLeft,
    required this.headerRight,
    // ── Passage ───────────────────────────────────────────────────────
    this.passageTitle,
    this.passageContent,
    this.passageExpanded = false,
    this.onPassageToggle,
    // ── Choices ───────────────────────────────────────────────────────
    required this.selectedAnswerIndex,
    // ── Explanation ───────────────────────────────────────────────────
    required this.explanationExpanded,
    required this.onExplanationToggle,
    required this.languageSelected,
    required this.onLanguageChange,
  });

  final QuestionModel question;

  /// Widget shown on the left side of the header row (e.g. subject chip or
  /// question-number text).
  final Widget headerLeft;

  /// Widget shown on the right side of the header row (e.g. result badge or
  /// "Answer shown" label).
  final Widget headerRight;

  // Passage
  final String? passageTitle;

  /// `null` while still loading — shows a spinner instead of content.
  final String? passageContent;
  final bool passageExpanded;
  final VoidCallback? onPassageToggle;

  /// The index that was selected by the user, or [question.correctOptionIndex]
  /// when always showing the answer (bookmark mode).
  final int selectedAnswerIndex;

  // Explanation
  final bool explanationExpanded;
  final VoidCallback onExplanationToggle;
  final RxString languageSelected;
  final ValueChanged<String> onLanguageChange;

  @override
  Widget build(BuildContext context) {
    final dark = AppHelperFunctions.isDark(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSizes.defaultSpace / 1.3),
      decoration: BoxDecoration(
        color: dark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(AppSizes.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ────────────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [headerLeft, headerRight],
          ),

          const Divider(height: AppSizes.lg),

          // ── Passage section (collapsible) ─────────────────────────────
          if (question.passageId != null) ...[
            _PassageSection(
              dark: dark,
              title: passageTitle,
              content: passageContent,
              expanded: passageExpanded,
              onToggle: onPassageToggle ?? () {},
            ),
            const SizedBox(height: AppSizes.spaceBtwItems),
          ],

          // ── Question text ─────────────────────────────────────────────
          QuestionSection(
            qnNumber: question.questionOrder,
            examQn: question.questionText,
          ),
          const SizedBox(height: AppSizes.spaceBtwItems),

          // ── Image ─────────────────────────────────────────────────────
          if (question.imageUrl != null) ...[
            ImageSection(imgUrl: question.imageUrl),
            const SizedBox(height: AppSizes.spaceBtwItems),
          ],

          // ── Options ───────────────────────────────────────────────────
          ...question.options.asMap().entries.map((entry) {
            return ChoiceButton(
              isChecked: true,
              selectedIndex: selectedAnswerIndex,
              optionTxt: entry.value,
              index: entry.key,
              questionId: question.id,
              correctIndex: question.correctOptionIndex,
            );
          }),

          // ── Explanation ───────────────────────────────────────────────
          AppExplanationBox(
            explanationEn: question.explanationEn,
            explanationAm: question.explanationAm,
            expanded: explanationExpanded,
            onToggle: onExplanationToggle,
            languageSelected: languageSelected,
            onLanguageChange: onLanguageChange,
          ),
        ],
      ),
    );
  }
}

// ── Private passage section ───────────────────────────────────────────────────

class _PassageSection extends StatelessWidget {
  const _PassageSection({
    required this.dark,
    required this.title,
    required this.content,
    required this.expanded,
    required this.onToggle,
  });

  final bool dark;

  /// Display title for the passage toggle button. Falls back to
  /// 'Reading Passage' when null or empty.
  final String? title;

  /// Passage body text. Pass `null` while loading to show a spinner.
  final String? content;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final displayTitle =
        (title != null && title!.isNotEmpty) ? title! : 'Reading Passage';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Toggle button ──────────────────────────────────────────────
        GestureDetector(
          onTap: onToggle,
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
                    displayTitle,
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

        // ── Passage body ───────────────────────────────────────────────
        if (expanded) ...[
          const SizedBox(height: AppSizes.sm),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSizes.md),
            decoration: BoxDecoration(
              color: dark ? AppColors.darkCard : Colors.white,
              borderRadius: BorderRadius.circular(AppSizes.sm),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.2),
              ),
            ),
            child: content == null
                ? const Padding(
                    padding: EdgeInsets.all(AppSizes.md),
                    child: Center(child: AppPulsingDots()),
                  )
                : Text.rich(
                    RichTextParser.parse(
                      content!,
                      GoogleFonts.lora(
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        height: 1.75,
                        color: dark ? AppColors.grey : AppColors.darkerGrey,
                      ),
                    ),
                  ),
          ),
        ],
      ],
    );
  }
}
