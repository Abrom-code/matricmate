import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:matricmate/features/personalization/controllers/analytics_controller.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

class AnalyticsSummaryGrid extends StatelessWidget {
  const AnalyticsSummaryGrid({super.key, required this.controller});
  final AnalyticsController controller;

  @override
  Widget build(BuildContext context) {
    final dark = AppHelperFunctions.isDark(context);
    final isLandscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;

    final readiness = controller.holisticReadiness;
    final avgScore = controller.avgScorePct.value;
    final tests = controller.testsCompleted.value;
    final notesCompleted = controller.completedNotesCount.value;
    final notesTotal = controller.totalNotesCount.value;

    String readinessTitle;
    Color readinessColor;
    String readinessSubtitle;

    if (tests == 0 && notesCompleted == 0) {
      readinessTitle = 'Ready to Begin';
      readinessColor = AppColors.primary;
      readinessSubtitle =
          'Start practicing tests and reading notes to calculate exam readiness';
    } else if (readiness >= 75) {
      readinessTitle = 'Exam Ready';
      readinessColor = const Color(0xFF10B981);
      readinessSubtitle =
          'Outstanding balance across tests and syllabus reading completion';
    } else if (readiness >= 50) {
      readinessTitle = 'On Track';
      readinessColor = const Color(0xFFF59E0B);
      readinessSubtitle =
          'Solid momentum! Review weaker chapters and read unread notes';
    } else {
      readinessTitle = 'Needs Practice';
      readinessColor = const Color(0xFFEF4444);
      readinessSubtitle =
          'Focus on core subject notes and retake low-scoring tests';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Top Hero: Exam Readiness Banner ──────────────────────────────────
        Container(
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
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Circular Readiness Gauge
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 66,
                    height: 66,
                    child: CircularProgressIndicator(
                      value: (tests == 0 && notesCompleted == 0)
                          ? 0.0
                          : (readiness / 100).clamp(0.0, 1.0),
                      strokeWidth: 6,
                      strokeCap: StrokeCap.round,
                      backgroundColor: dark
                          ? Colors.white.withValues(alpha: 0.08)
                          : const Color(0xFFE2E8F0),
                      valueColor: AlwaysStoppedAnimation<Color>(readinessColor),
                    ),
                  ),
                  Text(
                    (tests == 0 && notesCompleted == 0)
                        ? '0%'
                        : '${readiness.toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                      color: dark ? AppColors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),

              // Title & Context
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: readinessColor.withValues(
                                alpha: dark ? 0.22 : 0.12,
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              readinessTitle.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.4,
                                color: readinessColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '• Matric Readiness',
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
                    const SizedBox(height: 5),
                    Text(
                      readinessSubtitle,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: dark ? AppColors.white : const Color(0xFF1E293B),
                        height: 1.25,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // ── 4 Stats Grid ─────────────────────────────────────────────────────
        GridView.count(
          crossAxisCount: isLandscape ? 4 : 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: isLandscape ? 1.8 : 1.18,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _StatCard(
              icon: Iconsax.task_square_copy,
              iconColor: AppColors.primary,
              value: '$tests',
              label: 'Tests Completed',
              trend: tests > 0 ? '$tests taken' : 'Start now',
            ),
            _StatCard(
              icon: Iconsax.book_1_copy,
              iconColor: const Color(0xFF8B5CF6),
              value: '$notesCompleted${notesTotal > 0 ? "/$notesTotal" : ""}',
              label: 'Notes Read',
              trend: notesTotal > 0
                  ? '${(notesCompleted / notesTotal * 100).toStringAsFixed(0)}% read'
                  : 'Syllabus',
            ),
            _StatCard(
              icon: Iconsax.chart_copy,
              iconColor: const Color(0xFF0284C7),
              value: '${avgScore.toStringAsFixed(0)}%',
              label: 'Average Score',
              trend: avgScore >= 70 ? 'High' : 'Target 75%',
            ),
            _StatCard(
              icon: Iconsax.archive_tick_copy,
              iconColor: const Color(0xFFF59E0B),
              value: '${controller.bookmarkCount.value}',
              label: 'Saved Questions',
              trend: 'Revision',
            ),
          ],
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
    required this.trend,
  });

  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;
  final String trend;

  @override
  Widget build(BuildContext context) {
    final dark = AppHelperFunctions.isDark(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: dark ? AppColors.darkCard : AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: dark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: dark ? 0.22 : 0.12),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Center(
                  child: Icon(icon, color: iconColor, size: 17),
                ),
              ),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: dark ? 0.14 : 0.08),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    trend,
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color: iconColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: dark ? AppColors.white : const Color(0xFF0F172A),
                  letterSpacing: -0.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 1),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: dark ? AppColors.darkGrey : AppColors.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
