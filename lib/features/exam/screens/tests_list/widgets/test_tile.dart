import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

const _kResumeColor = Colors.indigo;

class TestTile extends StatelessWidget {
  const TestTile({
    super.key,
    required this.testName,
    this.icon = Icons.quiz,
    required this.onTap,
    this.hasSubTitle = true,
    required this.currentStep,
    required this.maxStep,
    this.iconColor = AppColors.primary,
    this.correctAnswers = 0,
    this.isInProgress = false,
    this.questionCount = 0,
    this.timeMinutes = -1,
    this.isNew = false,
  });

  final String testName;
  final IconData icon;
  final VoidCallback onTap;
  final bool hasSubTitle;
  final int currentStep, maxStep;
  final Color iconColor;
  final int correctAnswers;
  final bool isInProgress;
  final int questionCount;
  final int timeMinutes;
  /// When true, shows a "NEW" badge next to the test title.
  final bool isNew;

  @override
  Widget build(BuildContext context) {
    final dark = AppHelperFunctions.isDark(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final hasAttempt = maxStep > 0 && currentStep > 0;
    final progress = maxStep > 0
        ? (currentStep / maxStep).clamp(0.0, 1.0)
        : 0.0;

    // State-based values
    final Color barColor;
    final Widget metaRow;

    if (!hasAttempt) {
      // ── Not started ──────────────────────────────────────────────
      barColor = cs.outlineVariant.withValues(alpha: 0.4);
      metaRow = Row(
        children: [
          Icon(
            Iconsax.message_question_copy,
            size: 12,
            color: cs.onSurface.withValues(alpha: 0.4),
          ),
          const SizedBox(width: 4),
          Text(
            '$questionCount questions',
            style: tt.labelSmall?.copyWith(
              color: cs.onSurface.withValues(alpha: 0.4),
              fontSize: 11,
            ),
          ),
          if (timeMinutes > 0) ...[
            const SizedBox(width: 10),
            Icon(
              Iconsax.timer_1_copy,
              size: 12,
              color: cs.onSurface.withValues(alpha: 0.4),
            ),
            const SizedBox(width: 4),
            Text(
              '$timeMinutes min',
              style: tt.labelSmall?.copyWith(
                color: cs.onSurface.withValues(alpha: 0.4),
                fontSize: 11,
              ),
            ),
          ],
        ],
      );
    } else if (isInProgress) {
      // ── In progress ──────────────────────────────────────────────
      barColor = _kResumeColor;
      metaRow = Row(
        children: [
          const Icon(Icons.play_arrow_rounded, size: 13, color: _kResumeColor),
          const SizedBox(width: 4),
          Text(
            'Resume  ·  $currentStep / $maxStep',
            style: tt.labelSmall?.copyWith(
              color: _kResumeColor,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      );
    } else {
      // ── Completed ────────────────────────────────────────────────
      barColor = AppColors.primary;
      metaRow = Row(
        children: [
          const Icon(
            Icons.check_circle_outline_rounded,
            size: 13,
            color: AppColors.primary,
          ),
          const SizedBox(width: 4),
          Text(
            '$correctAnswers / $maxStep correct',
            style: tt.labelSmall?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      );
    }

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: isInProgress
                  ? _kResumeColor.withValues(alpha: 0.35)
                  : AppColors.primary.withValues(alpha: 0.18),
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              // ── Icon ────────────────────────────────────────────
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: dark ? 0.18 : 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),

              // ── Content ─────────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            testName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: tt.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: cs.onSurface,
                            ),
                          ),
                        ),
                        if (isNew) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              'NEW',
                              style: tt.labelSmall?.copyWith(
                                color: Colors.green,
                                fontWeight: FontWeight.w800,
                                fontSize: 9,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 5),

                    // Meta row (not started / resume / complete)
                    metaRow,
                    const SizedBox(height: 7),

                    // Progress bar (empty track for not-started)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 4,
                        backgroundColor: barColor.withValues(alpha: 0.12),
                        valueColor: AlwaysStoppedAnimation<Color>(barColor),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Chevron ─────────────────────────────────────────
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: cs.onSurface.withValues(alpha: 0.25),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
