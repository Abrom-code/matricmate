import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:matricmate/features/exam/controllers/question_controller.dart';
import 'package:matricmate/features/exam/models/result_model.dart';
import 'package:matricmate/routes/app_routes.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/constants/sizes.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

/// Parses the year and code from an entrance exam title.
/// Titles follow the pattern: first number = year, last number = code.
/// e.g. "2023 Physics 4" → (year: 2023, code: 4)
/// Returns null for either value if not found.
({int? year, int? code}) _parseEntranceTitle(String title) {
  final numbers = RegExp(
    r'\d+',
  ).allMatches(title).map((m) => int.parse(m.group(0)!)).toList();
  if (numbers.isEmpty) return (year: null, code: null);
  final year = numbers.first >= 1900 && numbers.first <= 2100
      ? numbers.first
      : null;
  final code = numbers.length >= 2 ? numbers.last : null;
  return (year: year, code: code);
}

class ReadyDialog extends StatelessWidget {
  const ReadyDialog({
    super.key,
    required this.qnCount,
    required this.time,
    required this.testId,
    required this.id,
    this.draft,
    this.examTitle,
  });

  final int qnCount, time, testId, id;

  /// Non-null when the user has an in-progress attempt to resume.
  final ResultModel? draft;

  /// When provided (entrance exams), year and code are parsed and displayed.
  final String? examTitle;

  void _launch({
    required bool examMode,
    bool isTimed = false,
    bool resume = false,
  }) {
    Get.delete<QuestionController>(force: true);
    Get.offNamed(
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

  @override
  Widget build(BuildContext context) {
    final dark = AppHelperFunctions.isDark(context);
    final hasDraft = draft != null;
    final answered = draft?.selectedAnswers.length ?? 0;

    // Parse year/code from entrance exam title if provided
    final parsed = examTitle != null ? _parseEntranceTitle(examTitle!) : null;
    final examYear = parsed?.year;
    final examCode = parsed?.code;
    final hasExamMeta = examYear != null || examCode != null;

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

                  // ── Entrance exam year & code chips ───────────────────
                  if (hasExamMeta) ...[
                    Row(
                      children: [
                        if (examYear != null)
                          _MetaChip(
                            icon: Icons.calendar_today_rounded,
                            label: '$examYear',
                            color: Colors.blueAccent,
                            dark: dark,
                          ),
                        if (examYear != null && examCode != null)
                          const SizedBox(width: 8),
                        if (examCode != null)
                          _MetaChip(
                            icon: Icons.tag_rounded,
                            label: 'Booklet Code: $examCode',
                            color: Colors.teal,
                            dark: dark,
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSizes.spaceBtwItems),
                  ],

                  // ── Action buttons ────────────────────────────────────
                  // Resume (only when draft exists)
                  if (hasDraft) ...[
                    Divider(color: AppColors.darkGrey.withValues(alpha: 0.15)),

                    Text(
                      'Continue',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppColors.darkGrey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSizes.spaceBtwItems),

                    _ActionButton(
                      label: 'Resume',
                      description:
                          'Continue from question ${answered + 1} where you left off',
                      icon: Icons.play_arrow_rounded,
                      color: Colors.indigo,
                      onTap: () {
                        // Detect original mode from saved state:
                        // - Had remaining seconds → was a timed exam
                        // - No checked questions → exam mode (answers hidden)
                        final wasExam = draft!.checkedQuestions.isEmpty;
                        final wasTimed = draft!.remainingSeconds > 0;
                        _launch(
                          examMode: wasExam,
                          isTimed: wasTimed,
                          resume: true,
                        );
                      },
                    ),
                    const SizedBox(height: AppSizes.spaceBtwItems),
                  ],
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
                    color: Colors.blue,
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
              icon: const Icon(
                Iconsax.close_circle_copy,
                color: AppColors.error,
                size: 22,
              ),
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

// ── Controller (kept minimal — no longer needs isExamMode toggle) ─────────────

class ReadyController extends GetxController {
  static ReadyController get instance => Get.find();
  final isExamMode = false.obs;

  void changeExamMode() {
    isExamMode.value = !isExamMode.value;
  }
}
