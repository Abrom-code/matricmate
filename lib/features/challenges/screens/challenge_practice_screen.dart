import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:matricmate/common/widgets/loaders/circular_loading.dart';
import 'package:matricmate/features/challenges/controllers/challenge_practice_controller.dart';
import 'package:matricmate/features/challenges/screens/widgets/challenge_question_box.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/constants/sizes.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

class ChallengePracticeScreen extends StatefulWidget {
  const ChallengePracticeScreen({
    super.key,
    required this.challengeId,
    required this.title,
    this.setId,
  });

  final String challengeId;
  final String title;
  final String? setId;

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
        challengeId: widget.challengeId,
        title: widget.title,
        setId: widget.setId,
      ),
      tag: 'practice_${widget.challengeId}',
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

        return Column(
          children: [
            // ── Top Navigation Bar ─────────────────────────────────
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

            // ── Standard App Question Box Template ─────────────────
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollCtrl,
                padding: const EdgeInsets.all(AppSizes.md),
                child: ChallengeQuestionBox(
                  key: ValueKey('practice_box_${q.id}'),
                  question: q,
                  orderIndex: _ctrl.currentIndex.value + 1,
                  totalQuestions: _ctrl.totalQuestions,
                  selectedChoice: selectedChoice,
                  onSelectChoice: (choice) => _ctrl.selectOption(choice),
                  isChecked: isAnswered,
                  showExplanation: isAnswered,
                  initialExplanationExpanded: true,
                ),
              ),
            ),

            // ── Bottom Controls ────────────────────────────────────
            SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: 10),
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
                        onPressed: _ctrl.finishPracticeAndReview,
                        icon: const Icon(Iconsax.tick_circle_copy, size: 16),
                        label: const Text('Finish & Review'),
                      ),
                  ],
                ),
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
