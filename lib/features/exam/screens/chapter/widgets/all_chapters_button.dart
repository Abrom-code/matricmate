import 'package:flutter/material.dart';
import 'package:matricmate/features/exam/models/chapter_progress_model.dart';
import 'package:matricmate/utils/constants/colors.dart';

class AllChaptersButton extends StatelessWidget {
  const AllChaptersButton({
    super.key,
    required this.onPressed,
    this.progress,
  });

  final VoidCallback onPressed;
  final ChapterProgressModel? progress;

  @override
  Widget build(BuildContext context) {
    final hasTests = progress?.hasTests ?? false;
    final totalTests = progress?.totalTests ?? 0;
    final completedTests = progress?.completedTests ?? 0;
    final isCompleted = progress?.isCompleted ?? false;
    final progressVal = progress?.progressPercentage ?? 0.0;
    final percentInt = (progressVal * 100).toInt();

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFF00796B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                // ── Left Icon Squircle ──────────────────────────────
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.layers_rounded,
                    color: AppColors.white,
                    size: 22,
                  ),
                ),

                const SizedBox(width: 14),

                // ── Title, Subtitle, & Progress Bar ──────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Practice All Chapters',
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.white,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        hasTests
                            ? '$totalTests ${totalTests == 1 ? "Combined Test" : "Combined Tests"} • Comprehensive Practice'
                            : 'Comprehensive grade-level exam practice',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),

                      // Progress bar when combined grade tests exist
                      if (hasTests) ...[
                        const SizedBox(height: 7),
                        Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: progressVal,
                                  minHeight: 4.5,
                                  backgroundColor:
                                      Colors.white.withValues(alpha: 0.22),
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isCompleted
                                  ? 'Done'
                                  : '$completedTests/$totalTests ($percentInt%)',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Colors.white.withValues(alpha: 0.95),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // ── Status Pill or Chevron ───────────────────────────
                if (isCompleted)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3.5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.45),
                        width: 1,
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          size: 13,
                          color: Colors.white,
                        ),
                        SizedBox(width: 3),
                        Text(
                          'Done',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.white,
                    size: 24,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
