import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:matricmate/features/exam/controllers/question_controller.dart';
import 'package:matricmate/features/exam/models/result_model.dart';
import 'package:matricmate/routes/app_routes.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/constants/sizes.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

class ReadyDialog extends StatelessWidget {
  const ReadyDialog({
    super.key,
    required this.qnCount,
    required this.time,
    required this.testId,
    required this.id,
    this.draft,
    this.examTitle,
    this.description,
  });

  final int qnCount, time, testId, id;

  /// Non-null when the user has an in-progress attempt to resume.
  final ResultModel? draft;

  /// Test title.
  final String? examTitle;

  /// Description or source info for the test.
  final String? description;

  void _launch({
    required bool examMode,
    bool isTimed = false,
    bool resume = false,
  }) {
    Get.delete<QuestionController>(force: true);
    Get.back(); // Cleanly dismiss ReadyDialog
    Get.toNamed(
      Routes.questions,
      arguments: {
        'test_id': testId,
        'is_timed': examMode || isTimed, // exam mode always implies timed
        'is_exam_mode': examMode,
        'time': time,
        'id': id,
        if (resume && draft != null) 'draft': draft,
      },
    );
  }

  void _showInfoSheet(BuildContext context) {
    final dark = AppHelperFunctions.isDark(context);
    final hasDescription =
        description != null && description!.trim().isNotEmpty;
    final hasTitle = examTitle != null && examTitle!.trim().isNotEmpty;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: dark ? AppColors.darkCard : AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.85,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: (dark ? AppColors.white : AppColors.darkerGrey)
                          .withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Sheet title
                Row(
                  children: [
                    const Icon(
                      Iconsax.info_circle_copy,
                      size: 20,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Test Details',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: dark ? AppColors.white : AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),

                if (hasTitle) ...[
                  const SizedBox(height: 12),
                  Text(
                    examTitle!.trim(),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: dark ? AppColors.white : AppColors.textPrimary,
                    ),
                  ),
                ],

                const SizedBox(height: 14),

                // Questions & Time info row
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _MetaChip(
                      icon: Iconsax.message_question_copy,
                      label: '$qnCount questions',
                      color: AppColors.primary,
                      dark: dark,
                    ),
                    if (time > 0)
                      _MetaChip(
                        icon: Iconsax.timer_1_copy,
                        label: '$time min',
                        color: Colors.blue,
                        dark: dark,
                      ),
                  ],
                ),

                // Description
                if (hasDescription) ...[
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(
                        alpha: dark ? 0.09 : 0.05,
                      ),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.primary.withValues(
                          alpha: dark ? 0.25 : 0.15,
                        ),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'DESCRIPTION',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          description!.trim(),
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.5,
                            color: dark
                                ? AppColors.white.withValues(alpha: 0.9)
                                : AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dark = AppHelperFunctions.isDark(context);
    final hasDraft = draft != null;
    final answered = draft?.selectedAnswers.length ?? 0;

    final hasDescription =
        description != null && description!.trim().isNotEmpty;
    final hasTitle = examTitle != null && examTitle!.trim().isNotEmpty;
    final hasInfo = hasDescription || hasTitle || time > 0 || qnCount > 0;

    return Dialog(
      backgroundColor: dark ? AppColors.darkCard : AppColors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.orientationOf(context) == Orientation.landscape
              ? MediaQuery.sizeOf(context).height * 0.85
              : 620,
          maxWidth: 480,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.defaultSpace),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header (Headline + Info & Close) ────────────────────
              Row(
                children: [
                  Expanded(
                    child: Text(
                      hasDraft ? 'Continue?' : 'Ready to start?',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800, fontSize: 20),
                    ),
                  ),
                  if (hasInfo) ...[
                    IconButton(
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                      constraints: const BoxConstraints(
                        minWidth: 24,
                        minHeight: 24,
                      ),
                      onPressed: () => _showInfoSheet(context),
                      tooltip: 'Test details',
                      icon: Icon(
                        Iconsax.info_circle_copy,
                        color: AppColors.primary.withValues(alpha: 0.8),
                        size: 20,
                      ),
                    ),
                  ],
                  IconButton(
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    constraints: const BoxConstraints(
                      minWidth: 24,
                      minHeight: 24,
                    ),
                    onPressed: () => Get.back(),
                    tooltip: 'Close',
                    icon: const Icon(
                      Iconsax.close_circle_copy,
                      color: AppColors.error,
                      size: 20,
                    ),
                  ),
                ],
              ),

              // ── Test Title (full width) ────────────────────────────
              if (hasTitle) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(
                      alpha: dark ? 0.10 : 0.06,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.primary.withValues(
                        alpha: dark ? 0.22 : 0.14,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          examTitle!.trim(),
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: dark
                                ? AppColors.white.withValues(alpha: 0.95)
                                : AppColors.textPrimary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: AppSizes.spaceBtwItems),

              // ── Resume button (only when in-progress draft exists) ──
              if (hasDraft) ...[
                _ActionButton(
                  label: 'Resume',
                  description:
                      'Continue from question ${answered + 1} where you left off',
                  icon: Icons.play_arrow_rounded,
                  color: AppColors.secondary,
                  onTap: () {
                    final wasExam = draft!.checkedQuestions.isEmpty;
                    final wasTimed = draft!.remainingSeconds > 0;
                    _launch(examMode: wasExam, isTimed: wasTimed, resume: true);
                  },
                ),
                const SizedBox(height: AppSizes.spaceBtwItems),
                Divider(
                  height: 1,
                  color: AppColors.darkGrey.withValues(alpha: 0.15),
                ),
                const SizedBox(height: AppSizes.spaceBtwItems),
                Text(
                  'Start fresh',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: AppColors.darkGrey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSizes.spaceBtwItems),
              ],

              // ── Practice button ──
              _ActionButton(
                label: 'Practice',
                description: 'Check answers as for each questions',
                icon: Iconsax.book_copy,
                color: AppColors.primary,
                onTap: () => _launch(examMode: false),
              ),

              const SizedBox(height: AppSizes.spaceBtwItems),

              // ── Exam button ──
              _ActionButton(
                label: 'Exam',
                description: 'Answers hidden until you finish. $time-min timer',
                icon: Iconsax.timer_1_copy,
                color: Colors.blue,
                onTap: () => _launch(examMode: true),
              ),

              const SizedBox(height: AppSizes.spaceBtwItems / 2),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Action button card ────────────────────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.description,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final String description;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dark = AppHelperFunctions.isDark(context);

    return Material(
      color: color.withValues(alpha: dark ? 0.15 : 0.08),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 12,
                        color: dark
                            ? AppColors.white.withValues(alpha: 0.55)
                            : AppColors.darkerGrey.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, size: 14, color: color),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Meta chip (year / code) ───────────────────────────────────────────────────

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.dark,
  });

  final IconData icon;
  final String label;
  final Color color;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: dark ? 0.18 : 0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
