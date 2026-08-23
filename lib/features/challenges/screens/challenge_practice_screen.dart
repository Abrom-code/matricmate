import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:matricmate/common/widgets/loaders/circular_loading.dart';
import 'package:matricmate/features/challenges/controllers/challenge_practice_controller.dart';
import 'package:matricmate/features/challenges/models/challenge_question_model.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/constants/sizes.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

class ChallengePracticeScreen extends StatefulWidget {
  const ChallengePracticeScreen({
    super.key,
    required this.setId,
    required this.title,
  });

  final String setId;
  final String title;

  @override
  State<ChallengePracticeScreen> createState() => _ChallengePracticeScreenState();
}

class _ChallengePracticeScreenState extends State<ChallengePracticeScreen> {
  late final ChallengePracticeController _ctrl;
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _ctrl = Get.put(
      ChallengePracticeController(
        setId: widget.setId,
        title: widget.title,
      ),
      tag: 'practice_${widget.setId}',
    );
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _showQuestionGrid(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PracticeGridSheet(controller: _ctrl),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dark = AppHelperFunctions.isDark(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Practice: ${widget.title}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
      ),
      body: Obx(() {
        if (_ctrl.isLoading.value) {
          return const AppCircularLoading(title: 'Loading practice questions...');
        }

        if (_ctrl.questions.isEmpty) {
          return const Center(child: Text('No questions found in this downloaded set.'));
        }

        final q = _ctrl.currentQuestion;
        final selectedChoice = _ctrl.userAnswers[q.id];
        final isAnswered = selectedChoice != null;

        // Parse correct index/choice
        int? correctIdx = int.tryParse(q.correctChoice);
        if (correctIdx == null) {
          final idx = q.choices.indexOf(q.correctChoice);
          if (idx != -1) correctIdx = idx;
        }

        return Column(
          children: [
            // Question status header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Question ${_ctrl.currentIndex.value + 1} of ${_ctrl.totalQuestions}',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Offline Self-Study',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Question, Choices, and Explanation
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollCtrl,
                padding: const EdgeInsets.all(AppSizes.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Question text
                    Container(
                      padding: const EdgeInsets.all(AppSizes.md),
                      decoration: BoxDecoration(
                        color: dark ? AppColors.darkCard : AppColors.white,
                        borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
                        border: Border.all(
                          color: dark ? AppColors.darkBorder : AppColors.borderPrimary,
                        ),
                      ),
                      child: Text(
                        q.questionText,
                        style: const TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSizes.spaceBtwSections),

                    // Choices list with instant evaluation
                    for (int idx = 0; idx < q.choices.length; idx++) ...[
                      Builder(
                        builder: (context) {
                          final choiceText = q.choices[idx];
                          final optionLetter = String.fromCharCode(65 + idx);
                          final isThisChoiceSelected =
                              selectedChoice == choiceText || selectedChoice == idx.toString();
                          final isThisChoiceCorrect =
                              (correctIdx != null && correctIdx == idx) || (q.correctChoice == choiceText);

                          Color? bgColor;
                          Color borderColor = dark ? AppColors.darkBorder : AppColors.borderPrimary;
                          Widget? trailingIcon;

                          if (isAnswered) {
                            if (isThisChoiceCorrect) {
                              bgColor = AppColors.success.withValues(alpha: 0.15);
                              borderColor = AppColors.success;
                              trailingIcon = const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 20);
                            } else if (isThisChoiceSelected && !isThisChoiceCorrect) {
                              bgColor = AppColors.error.withValues(alpha: 0.15);
                              borderColor = AppColors.error;
                              trailingIcon = const Icon(Icons.cancel_rounded, color: AppColors.error, size: 20);
                            }
                          }

                          return Padding(
                            padding: const EdgeInsets.only(bottom: AppSizes.sm + 4),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
                              onTap: () => _ctrl.selectOption(choiceText),
                              child: Container(
                                padding: const EdgeInsets.all(AppSizes.md),
                                decoration: BoxDecoration(
                                  color: bgColor ?? (dark ? AppColors.darkCard : AppColors.white),
                                  borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
                                  border: Border.all(
                                    color: borderColor,
                                    width: (isThisChoiceSelected || (isAnswered && isThisChoiceCorrect)) ? 1.8 : 1.0,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 32,
                                      height: 32,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: (isAnswered && isThisChoiceCorrect)
                                            ? AppColors.success
                                            : (isAnswered && isThisChoiceSelected
                                                ? AppColors.error
                                                : (dark ? AppColors.darkContainer : AppColors.grey.withValues(alpha: 0.2))),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Text(
                                        optionLetter,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13,
                                          color: (isAnswered && (isThisChoiceCorrect || isThisChoiceSelected))
                                              ? Colors.white
                                              : (dark ? Colors.white : Colors.black87),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: AppSizes.md),
                                    Expanded(
                                      child: Text(
                                        choiceText,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: (isThisChoiceSelected || (isAnswered && isThisChoiceCorrect))
                                              ? FontWeight.w700
                                              : FontWeight.normal,
                                        ),
                                      ),
                                    ),
                                    if (trailingIcon != null) trailingIcon,
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],

                    // Instant Explanation Card (revealed after answering)
                    if (isAnswered && q.hasExplanation) ...[
                      const SizedBox(height: AppSizes.md),
                      _ChallengeBilingualExplanationCard(question: q),
                    ],
                  ],
                ),
              ),
            ),

            // Bottom navigation
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: 12),
              decoration: BoxDecoration(
                color: dark ? AppColors.darkCard : AppColors.white,
                border: Border(
                  top: BorderSide(
                    color: dark ? AppColors.darkBorder : AppColors.borderPrimary,
                  ),
                ),
              ),
              child: Row(
                children: [
                  IconButton.outlined(
                    onPressed: _ctrl.currentIndex.value > 0 ? _ctrl.prevQuestion : null,
                    icon: const Icon(Iconsax.arrow_left_2_copy, size: 18),
                  ),
                  const SizedBox(width: AppSizes.sm),
                  OutlinedButton.icon(
                    onPressed: () => _showQuestionGrid(context),
                    icon: const Icon(Iconsax.grid_4_copy, size: 16),
                    label: Text('${_ctrl.currentIndex.value + 1}/${_ctrl.totalQuestions}'),
                  ),
                  const Spacer(),
                  if (_ctrl.currentIndex.value < _ctrl.totalQuestions - 1)
                    FilledButton.icon(
                      onPressed: _ctrl.nextQuestion,
                      icon: const Icon(Iconsax.arrow_right_3_copy, size: 16),
                      label: const Text('Next'),
                    )
                  else
                    FilledButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Iconsax.tick_circle_copy, size: 16),
                      label: const Text('Finish Review'),
                    ),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }
}

// ── Practice Grid Sheet ──────────────────────────────────────────────────────

class _PracticeGridSheet extends StatelessWidget {
  const _PracticeGridSheet({required this.controller});

  final ChallengePracticeController controller;

  @override
  Widget build(BuildContext context) {
    final dark = AppHelperFunctions.isDark(context);

    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: dark ? AppColors.darkCard : AppColors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSizes.borderRadiusLg)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Practice Questions Navigator',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.sm),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(controller.totalQuestions, (idx) {
                final q = controller.questions[idx];
                final isAnswered = controller.userAnswers.containsKey(q.id);
                final isCurrent = controller.currentIndex.value == idx;

                Color bg;
                Color fg;
                if (isCurrent) {
                  bg = AppColors.primary;
                  fg = Colors.white;
                } else if (isAnswered) {
                  bg = AppColors.primary.withValues(alpha: 0.2);
                  fg = AppColors.primary;
                } else {
                  bg = dark ? AppColors.darkContainer : AppColors.grey.withValues(alpha: 0.2);
                  fg = dark ? Colors.white70 : AppColors.darkGrey;
                }

                return InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () {
                    controller.goToQuestion(idx);
                    Navigator.pop(context);
                  },
                  child: Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: bg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isCurrent ? AppColors.primary : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      '${idx + 1}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: fg,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChallengeBilingualExplanationCard extends StatefulWidget {
  const _ChallengeBilingualExplanationCard({required this.question});

  final ChallengeQuestionModel question;

  @override
  State<_ChallengeBilingualExplanationCard> createState() => _ChallengeBilingualExplanationCardState();
}

class _ChallengeBilingualExplanationCardState extends State<_ChallengeBilingualExplanationCard> {
  late String _selectedLang; // 'en' or 'am'

  @override
  void initState() {
    super.initState();
    if (widget.question.explanationEn.isNotEmpty) {
      _selectedLang = 'en';
    } else if (widget.question.explanationAm.isNotEmpty) {
      _selectedLang = 'am';
    } else {
      _selectedLang = 'en';
    }
  }

  @override
  void didUpdateWidget(covariant _ChallengeBilingualExplanationCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.question.id != widget.question.id) {
      if (widget.question.explanationEn.isNotEmpty) {
        _selectedLang = 'en';
      } else if (widget.question.explanationAm.isNotEmpty) {
        _selectedLang = 'am';
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = AppHelperFunctions.isDark(context);
    final hasBoth = widget.question.hasBothExplanations;
    final textToShow = _selectedLang == 'am'
        ? (widget.question.explanationAm.isNotEmpty ? widget.question.explanationAm : widget.question.explanation)
        : (widget.question.explanationEn.isNotEmpty ? widget.question.explanationEn : widget.question.explanation);

    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Iconsax.lamp_charge_copy, color: AppColors.primary, size: 18),
              const SizedBox(width: 6),
              Text(
                _selectedLang == 'am' ? 'አማርኛ ማብራሪያ' : 'Explanation',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: AppColors.primary,
                ),
              ),
              const Spacer(),
              if (hasBoth)
                Container(
                  decoration: BoxDecoration(
                    color: dark ? AppColors.darkCard : AppColors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                  ),
                  padding: const EdgeInsets.all(2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _LangPill(
                        label: 'English',
                        isSelected: _selectedLang == 'en',
                        onTap: () => setState(() => _selectedLang = 'en'),
                      ),
                      _LangPill(
                        label: 'አማርኛ',
                        isSelected: _selectedLang == 'am',
                        onTap: () => setState(() => _selectedLang = 'am'),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            textToShow,
            style: const TextStyle(fontSize: 13, height: 1.45),
          ),
        ],
      ),
    );
  }
}

class _LangPill extends StatelessWidget {
  const _LangPill({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

