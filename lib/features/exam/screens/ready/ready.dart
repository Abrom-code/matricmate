import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:matricmate/features/exam/controllers/question_controller.dart';
import 'package:matricmate/features/exam/models/result_model.dart';
import 'package:matricmate/features/exam/screens/ready/widgets/attribute_box.dart';
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
  });

  final int qnCount, time, testId, id;

  /// Non-null when the user has an in-progress attempt to resume.
  final ResultModel? draft;

  void _launch({required bool examMode, bool resume = false}) {
    Get.delete<QuestionController>(force: true);
    Get.offNamed(
      Routes.questions,
      arguments: {
        'test_id': testId,
        'is_timed': examMode,
        'is_exam_mode': examMode,
        'time': time,
        'id': id,
        if (resume && draft != null) 'draft': draft,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final dark = AppHelperFunctions.isDark(context);
    final hasDraft = draft != null;
    final answered = draft?.selectedAnswers.length ?? 0;

    return Dialog(
      backgroundColor: dark ? AppColors.darkCard : AppColors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Stack(
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 620),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSizes.defaultSpace,
                AppSizes.defaultSpace,
                AppSizes.defaultSpace,
                AppSizes.defaultSpace,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Title ─────────────────────────────────────────────
                  const SizedBox(height: AppSizes.xs),
                  Text(
                    hasDraft ? 'Continue?' : 'Ready to start?',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: AppSizes.spaceBtwItems),

                  // ── Stats ──────────────────────────────────────────────
                  Center(
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      spacing: AppSizes.defaultSpace / 2,
                      runSpacing: AppSizes.spaceBtwItems,
                      children: [
                        AttributeBox(
                          icon: Iconsax.message_question_copy,
                          value: qnCount,
                          label: 'questions',
                        ),
                        AttributeBox(
                          icon: Iconsax.timer_1_copy,
                          value: time,
                          label: 'minutes',
                        ),
                      ],
                    ),
                  ),

                  // ── In-progress banner ────────────────────────────────
                  if (hasDraft) ...[
                    const SizedBox(height: AppSizes.spaceBtwItems),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.orange.withValues(alpha: 0.40),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline_rounded,
                              size: 16, color: Colors.orange.shade700),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'You answered $answered of $qnCount questions last time.',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.orange.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: AppSizes.spaceBtwSections),

                  // ── Action buttons ────────────────────────────────────
                  // Resume (only when draft exists)
                  if (hasDraft) ...[
                    _ActionButton(
                      label: 'Resume',
                      description:
                          'Continue from question ${answered + 1} where you left off',
                      icon: Icons.play_arrow_rounded,
                      color: Colors.orange.shade600,
                      onTap: () => _launch(
                        examMode: draft!.isCompleted == false &&
                                draft!.checkedQuestions.isEmpty
                            ? true   // was exam mode draft
                            : false, // default to practice on resume
                        resume: true,
                      ),
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

                  // Practice button
                  _ActionButton(
                    label: 'Practice',
                    description:
                        'Check answers as you go — no timer, no pressure',
                    icon: Iconsax.book_copy,
                    color: AppColors.primary,
                    onTap: () => _launch(examMode: false),
                  ),

                  const SizedBox(height: AppSizes.spaceBtwItems),

                  // Exam button
                  _ActionButton(
                    label: 'Exam',
                    description:
                        'Answers hidden until you finish. $time-min timer applies',
                    icon: Iconsax.timer_1_copy,
                    color: Colors.deepPurple.shade400,
                    onTap: () => _launch(examMode: true),
                  ),

                  const SizedBox(height: AppSizes.spaceBtwItems / 2),
                ],
              ),
            ),
          ),

          // Close button
          Positioned(
            top: 6,
            right: 6,
            child: IconButton(
              onPressed: () => Get.back(),
              icon: const Icon(Iconsax.close_circle_copy,
                  color: AppColors.error, size: 22),
            ),
          ),
        ],
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

// ── Controller (kept minimal — no longer needs isExamMode toggle) ─────────────

class ReadyController extends GetxController {
  static ReadyController get instance => Get.find();
  final isExamMode = false.obs;

  void changeExamMode() {
    isExamMode.value = !isExamMode.value;
  }
}
