import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:matricmate/common/widgets/loaders/circular_loading.dart';
import 'package:matricmate/features/challenges/controllers/challenge_attempt_controller.dart';
import 'package:matricmate/features/challenges/screens/widgets/challenge_question_box.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/constants/sizes.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

class ChallengeAttemptScreen extends StatefulWidget {
  const ChallengeAttemptScreen({
    super.key,
    required this.challengeId,
    required this.title,
  });

  final String challengeId;
  final String title;

  @override
  State<ChallengeAttemptScreen> createState() => _ChallengeAttemptScreenState();
}

class _ChallengeAttemptScreenState extends State<ChallengeAttemptScreen> {
  late final ChallengeAttemptController _ctrl;
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _ctrl = Get.put(
      ChallengeAttemptController(
        challengeId: widget.challengeId,
        title: widget.title,
      ),
      tag: 'challenge_attempt_${widget.challengeId}',
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
      builder: (_) => _QuestionGridSheet(controller: _ctrl),
    );
  }

  void _confirmSubmit(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Submit Challenge Attempt?'),
        content: Text(
          'You have answered ${_ctrl.answeredCount} of ${_ctrl.totalQuestions} questions.\n\nOnce submitted, your final score and time will be locked and ranked on the leaderboard.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Continue Testing'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _ctrl.submitAttempt();
            },
            child: const Text('Submit Now'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dark = AppHelperFunctions.isDark(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Exit Live Challenge?'),
            content: const Text(
              'The timer will continue running in the background. Are you sure you want to exit?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Stay & Continue'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: const Text(
                  'Exit',
                  style: TextStyle(color: AppColors.error),
                ),
              ),
            ],
          ),
        );
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          actions: [
            // ── Live Timer Badge ────────────────────────────────────
            Obx(() {
              final isUrgent = _ctrl.remainingSeconds.value < 300; // < 5 mins
              return Container(
                margin: const EdgeInsets.only(right: AppSizes.md),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isUrgent
                      ? AppColors.error.withValues(alpha: 0.15)
                      : AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isUrgent ? AppColors.error : AppColors.primary,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Iconsax.timer_1_copy,
                      size: 14,
                      color: isUrgent ? AppColors.error : AppColors.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _ctrl.formattedRemainingTime,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: isUrgent ? AppColors.error : AppColors.primary,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
        body: Obx(() {
          if (_ctrl.isLoading.value) {
            return const AppCircularLoading(title: 'Loading challenge questions...');
          }

          if (_ctrl.questions.isEmpty) {
            return const Center(child: Text('No questions available in this challenge.'));
          }

          final currentQ = _ctrl.questions[_ctrl.currentIndex.value];
          final selectedChoice = _ctrl.userAnswers[currentQ.id];

          return Column(
            children: [
              // ── Linear Progress Bar ───────────────────────────────
              LinearProgressIndicator(
                value: _ctrl.progress,
                minHeight: 4,
                backgroundColor: dark ? AppColors.darkBorder : AppColors.borderPrimary,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),

              // ── Question Header Info ──────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: AppSizes.sm),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Question ${_ctrl.currentIndex.value + 1} of ${_ctrl.totalQuestions}',
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                    Text(
                      '${_ctrl.answeredCount} Answered',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),

              // ── Question Box Template ────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.all(AppSizes.md),
                  child: ChallengeQuestionBox(
                    key: ValueKey('attempt_box_${currentQ.id}'),
                    question: currentQ,
                    orderIndex: _ctrl.currentIndex.value + 1,
                    totalQuestions: _ctrl.totalQuestions,
                    selectedChoice: selectedChoice,
                    onSelectChoice: (choice) => _ctrl.selectChoice(currentQ.id, choice),
                    isChecked: false,
                    showExplanation: false,
                  ),
                ),
              ),

              // ── Bottom Navigation & Submit Bar ────────────────────
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
                    // Previous
                    IconButton.outlined(
                      onPressed: _ctrl.currentIndex.value > 0 ? _ctrl.prevQuestion : null,
                      icon: const Icon(Iconsax.arrow_left_2_copy, size: 18),
                    ),
                    const SizedBox(width: AppSizes.sm),

                    // Grid / Sheet button
                    OutlinedButton.icon(
                      onPressed: () => _showQuestionGrid(context),
                      icon: const Icon(Iconsax.grid_4_copy, size: 16),
                      label: Text('${_ctrl.currentIndex.value + 1}/${_ctrl.totalQuestions}'),
                    ),
                    const Spacer(),

                    // Next / Finish
                    if (_ctrl.currentIndex.value < _ctrl.totalQuestions - 1)
                      FilledButton.icon(
                        onPressed: _ctrl.nextQuestion,
                        icon: const Icon(Iconsax.arrow_right_3_copy, size: 16),
                        label: const Text('Next'),
                      )
                    else
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.success,
                        ),
                        onPressed: () => _confirmSubmit(context),
                        icon: const Icon(Iconsax.tick_circle_copy, size: 16),
                        label: const Text('Submit Attempt'),
                      ),
                  ],
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

// ── Question Grid Navigator Sheet ────────────────────────────────────────────

class _QuestionGridSheet extends StatelessWidget {
  const _QuestionGridSheet({required this.controller});

  final ChallengeAttemptController controller;

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
                  'Question Navigator',
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
            const SizedBox(height: AppSizes.lg),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                controller.submitAttempt();
              },
              child: const Text('Finish & Submit Attempt'),
            ),
          ],
        ),
      ),
    );
  }
}
