import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matricmate/common/widgets/exam/explanation_box.dart';
import 'package:matricmate/features/challenges/models/challenge_question_model.dart';
import 'package:matricmate/features/exam/screens/question/widgets/choice_button.dart';
import 'package:matricmate/features/exam/screens/question/widgets/image_section.dart';
import 'package:matricmate/features/exam/screens/question/widgets/question_section.dart';
import 'package:matricmate/features/exam/screens/result/widgets/correct_check_button.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/constants/sizes.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

/// Reusable app-standard question template box for Challenge attempts, practice, and review.
class ChallengeQuestionBox extends StatefulWidget {
  const ChallengeQuestionBox({
    super.key,
    required this.question,
    required this.orderIndex,
    required this.totalQuestions,
    required this.selectedChoice,
    this.onSelectChoice,
    this.isChecked = false,
    this.showExplanation = false,
    this.initialExplanationExpanded = false,
  });

  final ChallengeQuestionModel question;
  final int orderIndex;
  final int totalQuestions;
  final String? selectedChoice;
  final ValueChanged<String>? onSelectChoice;
  final bool isChecked;
  final bool showExplanation;
  final bool initialExplanationExpanded;

  @override
  State<ChallengeQuestionBox> createState() => _ChallengeQuestionBoxState();
}

class _ChallengeQuestionBoxState extends State<ChallengeQuestionBox> {
  late bool _explanationExpanded;
  final _languageSelected = 'en'.obs;

  @override
  void initState() {
    super.initState();
    _explanationExpanded = widget.initialExplanationExpanded;
  }

  @override
  Widget build(BuildContext context) {
    final dark = AppHelperFunctions.isDark(context);
    final q = widget.question;

    // Determine correct option index
    int correctIndex = -1;
    final parsedIdx = int.tryParse(q.correctChoice);
    if (parsedIdx != null) {
      correctIndex = parsedIdx;
    } else {
      correctIndex = q.choices.indexOf(q.correctChoice);
    }

    // Determine selected option index
    int selectedIndex = -1;
    if (widget.selectedChoice != null) {
      final sIdx = int.tryParse(widget.selectedChoice!);
      if (sIdx != null) {
        selectedIndex = sIdx;
      } else {
        selectedIndex = q.choices.indexOf(widget.selectedChoice!);
      }
    }

    final isCorrect = widget.isChecked && selectedIndex != -1 && (selectedIndex == correctIndex || widget.selectedChoice == q.correctChoice);
    final isSkipped = widget.isChecked && (widget.selectedChoice == null || widget.selectedChoice!.isEmpty || selectedIndex == -1);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: dark ? AppColors.darkCard : AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: dark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? 0.25 : 0.04),
            blurRadius: 14,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header Row ─────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Q${widget.orderIndex} of ${widget.totalQuestions}',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                  ),
                ),
              ),
              if (widget.isChecked) ...[
                if (isSkipped)
                  const CorrectCheckButton(
                    color: Color(0xFFF59E0B),
                    icon: Icons.timer_outlined,
                    text: 'Skipped',
                  )
                else if (isCorrect)
                  const CorrectCheckButton(
                    color: Color(0xFF10B981),
                    icon: Icons.check_circle_rounded,
                    text: 'Correct',
                  )
                else
                  const CorrectCheckButton(
                    color: Color(0xFFEF4444),
                    icon: Icons.cancel_rounded,
                    text: 'Wrong',
                  ),
              ],
            ],
          ),

          Divider(
            height: 24,
            thickness: 1,
            color: dark ? AppColors.darkBorder : const Color(0xFFF1F5F9),
          ),

          // ── Question Text ──────────────────────────────────────────
          QuestionSection(
            qnNumber: widget.orderIndex,
            examQn: q.questionText,
          ),
          const SizedBox(height: AppSizes.spaceBtwItems),

          // ── Image Section (if present) ─────────────────────────────
          if (q.imageUrl != null && q.imageUrl!.isNotEmpty) ...[
            ImageSection(imgUrl: q.imageUrl),
            const SizedBox(height: AppSizes.spaceBtwItems),
          ],

          // ── Choices List ───────────────────────────────────────────
          for (int idx = 0; idx < q.choices.length; idx++) ...[
            ChoiceButton(
              optionTxt: q.choices[idx],
              index: idx,
              questionId: q.id.hashCode,
              correctIndex: correctIndex,
              selectedIndex: selectedIndex,
              isChecked: widget.isChecked,
              onTap: widget.onSelectChoice != null
                  ? () => widget.onSelectChoice!(q.choices[idx])
                  : null,
            ),
          ],

          // ── Explanation Box ────────────────────────────────────────
          if (widget.showExplanation && q.hasExplanation) ...[
            const SizedBox(height: AppSizes.spaceBtwItems),
            AppExplanationBox(
              explanationEn: q.explanationEn.isNotEmpty ? q.explanationEn : q.explanation,
              explanationAm: q.explanationAm.isNotEmpty ? q.explanationAm : 'No Amharic Explanation!',
              expanded: _explanationExpanded,
              onToggle: () => setState(() => _explanationExpanded = !_explanationExpanded),
              languageSelected: _languageSelected,
              onLanguageChange: (lang) => _languageSelected.value = lang,
            ),
          ],
        ],
      ),
    );
  }
}
