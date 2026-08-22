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

    final avgScore = controller.avgScorePct.value;
    final tests = controller.testsCompleted.value;

    String readinessTitle;
    Color readinessColor;
    String readinessSubtitle;

    if (tests == 0) {
      readinessTitle = 'Ready to Begin';
      readinessColor = AppColors.primary;
      readinessSubtitle = 'Take your first test to calculate readiness';
    } else if (avgScore >= 75) {
      readinessTitle = 'Exam Ready';
      readinessColor = const Color(0xFF10B981);
      readinessSubtitle = 'Great mastery across practiced subjects';
    } else if (avgScore >= 50) {
      readinessTitle = 'On Track';
      readinessColor = const Color(0xFFF59E0B);
      readinessSubtitle = 'Consistent progress, focus on weaker topics';
    } else {
      readinessTitle = 'Needs Practice';
      readinessColor = const Color(0xFFEF4444);
      readinessSubtitle = 'Review key chapters and entrance questions';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Top Hero: Exam Readiness Banner ──────────────────────────────────
        Container(
          padding: const EdgeInsets.all(18),
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
                    width: 68,
                    height: 68,
                    child: CircularProgressIndicator(
                      value: tests == 0 ? 0.0 : (avgScore / 100).clamp(0.0, 1.0),
                      strokeWidth: 6,
                      strokeCap: StrokeCap.round,
                      backgroundColor: dark
                          ? Colors.white.withValues(alpha: 0.08)
                          : const Color(0xFFE2E8F0),
                      valueColor: AlwaysStoppedAnimation<Color>(readinessColor),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        tests == 0 ? '0%' : '${avgScore.toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                          color: dark ? AppColors.white : const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(width: 18),

              // Title & Context
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
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
                              letterSpacing: 0.5,
                              color: readinessColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '• Readiness',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: dark
                                ? AppColors.darkGrey
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      readinessSubtitle,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: dark ? AppColors.white : const Color(0xFF1E293B),
                        height: 1.3,
                      ),
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
          childAspectRatio: isLandscape ? 1.8 : 1.35,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _StatCard(
              icon: Iconsax.task_square_copy,
              iconColor: AppColors.primary,
              value: '$tests',
              label: 'Tests Completed',
              trend: tests > 0 ? '$tests done' : 'Get started',
            ),
            _StatCard(
              icon: Iconsax.chart_copy,
              iconColor: const Color(0xFF0284C7),
              value: '${avgScore.toStringAsFixed(0)}%',
              label: 'Average Score',
              trend: avgScore >= 70 ? 'High mastery' : 'Target 75%+',
            ),
            _StatCard(
              icon: Icons.check_circle_outline_rounded,
              iconColor: const Color(0xFF10B981),
              value: _formatNumber(controller.totalCorrect.value),
              label: 'Correct Answers',
              trend: 'All-time practice',
            ),
            _StatCard(
              icon: Iconsax.archive_tick_copy,
              iconColor: const Color(0xFFF59E0B),
              value: '${controller.bookmarkCount.value}',
              label: 'Saved Questions',
              trend: 'Bookmarked for review',
            ),
          ],
        ),
      ],
    );
  }

  String _formatNumber(int n) {
    if (n >= 1000) {
      return '${(n / 1000).toStringAsFixed(n % 1000 == 0 ? 0 : 1)}k';
    }
    return '$n';
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
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
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
            blurRadius: 10,
            offset: const Offset(0, 3),
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
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: dark ? 0.22 : 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Icon(icon, color: iconColor, size: 19),
                ),
              ),
              Container(
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
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: dark ? AppColors.white : const Color(0xFF0F172A),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.5,
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
