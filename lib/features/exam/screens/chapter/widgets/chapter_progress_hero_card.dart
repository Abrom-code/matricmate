import 'package:flutter/material.dart';
import 'package:matricmate/features/exam/models/chapter_progress_model.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

class ChapterProgressHeroCard extends StatelessWidget {
  const ChapterProgressHeroCard({
    super.key,
    required this.summary,
    required this.categoryTitle,
    this.isSection = false,
  });

  final GradeProgressSummary summary;
  final String categoryTitle;
  final bool isSection;

  @override
  Widget build(BuildContext context) {
    final dark = AppHelperFunctions.isDark(context);
    final percentage = summary.progressPercentage;
    final percentInt = (percentage * 100).toInt();
    final isMastered = summary.isCompleted && summary.totalTests > 0;
    final hasActivity = summary.completedTests > 0 || summary.inProgressTests > 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: dark ? AppColors.darkCard : AppColors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isMastered
              ? AppColors.success.withValues(alpha: dark ? 0.35 : 0.25)
              : (dark ? AppColors.darkBorder : AppColors.borderPrimary),
          width: isMastered ? 1.4 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? 0.25 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top Header Row ──────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Category tag pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(
                    alpha: dark ? 0.18 : 0.08,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isSection
                          ? Icons.dashboard_outlined
                          : Icons.auto_stories_outlined,
                      size: 13,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      categoryTitle.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),

              // Status Badge
              if (isMastered)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(
                      alpha: dark ? 0.20 : 0.12,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.verified_rounded,
                        size: 13,
                        color: AppColors.success,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Mastered',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                )
              else if (hasActivity)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withValues(
                      alpha: dark ? 0.20 : 0.12,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.bolt_rounded,
                        size: 13,
                        color: Color(0xFF3B82F6),
                      ),
                      SizedBox(width: 4),
                      Text(
                        'In Progress',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF3B82F6),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: dark ? AppColors.darkSurface : AppColors.lightGrey,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Not Started',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: dark ? AppColors.darkGrey : AppColors.textSecondary,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 14),

          // ── Main Content: Circular Meter + Text & Linear Bar ────
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Radial Progress Gauge
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 52,
                    height: 52,
                    child: CircularProgressIndicator(
                      value: percentage > 0 ? percentage : 0.001,
                      strokeWidth: 4.8,
                      strokeCap: StrokeCap.round,
                      backgroundColor: dark
                          ? AppColors.darkSurface
                          : AppColors.primary.withValues(alpha: 0.10),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isMastered ? AppColors.success : AppColors.primary,
                      ),
                    ),
                  ),
                  if (isMastered)
                    const Icon(
                      Icons.check_rounded,
                      size: 24,
                      color: AppColors.success,
                    )
                  else
                    Text(
                      '$percentInt%',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.4,
                        color: dark ? AppColors.textWhite : AppColors.textPrimary,
                      ),
                    ),
                ],
              ),

              const SizedBox(width: 14),

              // Title, metrics, and linear bar
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          summary.totalTests > 0
                              ? '${summary.completedTests} of ${summary.totalTests} Tests'
                              : 'No Tests Available',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                            color: dark
                                ? AppColors.textWhite
                                : AppColors.textPrimary,
                          ),
                        ),
                        if (summary.totalChapters > 0)
                          Text(
                            '${summary.completedChapters}/${summary.totalChapters} ${isSection ? "Sections" : "Chapters"}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: dark
                                  ? AppColors.darkGrey
                                  : AppColors.textSecondary,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Linear bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: percentage,
                        minHeight: 6,
                        backgroundColor: dark
                            ? AppColors.darkSurface
                            : AppColors.primary.withValues(alpha: 0.10),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isMastered ? AppColors.success : AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
