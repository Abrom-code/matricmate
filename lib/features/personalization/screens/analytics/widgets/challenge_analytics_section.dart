import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:matricmate/controllers/navigation_controller.dart';
import 'package:matricmate/features/personalization/controllers/analytics_controller.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/constants/sizes.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

class ChallengeAnalyticsSection extends StatelessWidget {
  const ChallengeAnalyticsSection({super.key, required this.controller});
  final AnalyticsController controller;

  @override
  Widget build(BuildContext context) {
    final dark = AppHelperFunctions.isDark(context);

    return Obx(() {
      final total = controller.totalChallengesTaken.value;
      final thisWeek = controller.challengesThisWeek.value;
      final thisMonth = controller.challengesThisMonth.value;
      final avgScore = controller.challengeAvgScorePct.value;
      final timeStr = controller.formattedChallengeTime;

      String streakMessage;
      Color streakColor;
      if (thisWeek >= 3) {
        streakMessage = 'Outstanding activity! You completed $thisWeek rounds this week.';
        streakColor = const Color(0xFF10B981);
      } else if (thisWeek > 0) {
        streakMessage = '$thisWeek challenge${thisWeek == 1 ? '' : 's'} taken this week. Keep challenging yourself!';
        streakColor = const Color(0xFFF59E0B);
      } else {
        streakMessage = 'No challenges taken this week. Join live rounds to climb standings!';
        streakColor = dark ? Colors.white60 : AppColors.textSecondary;
      }

      return Container(
        padding: const EdgeInsets.all(AppSizes.md),
        decoration: BoxDecoration(
          color: dark ? AppColors.darkCard : Colors.white,
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header Row ──────────────────────────────────────────────────
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Iconsax.cup_copy,
                    size: 18,
                    color: Color(0xFFF59E0B),
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Challenge Activity',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'Weekly & monthly round participation',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => NavigationController.navigateToTab(1),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Arena',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        SizedBox(width: 2),
                        Icon(
                          Iconsax.arrow_right_3_copy,
                          size: 11,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // ── 4-Metric Grid (Week, Month, Total, Accuracy) ────────────────
            Row(
              children: [
                Expanded(
                  child: _MetricTile(
                    title: 'This Week',
                    value: '$thisWeek',
                    unit: 'rounds',
                    icon: Iconsax.calendar_1_copy,
                    accentColor: const Color(0xFF10B981),
                    dark: dark,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MetricTile(
                    title: 'This Month',
                    value: '$thisMonth',
                    unit: 'rounds',
                    icon: Iconsax.calendar_tick_copy,
                    accentColor: const Color(0xFF8B5CF6),
                    dark: dark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _MetricTile(
                    title: 'Total Rounds',
                    value: '$total',
                    unit: 'all-time',
                    icon: Iconsax.ranking_copy,
                    accentColor: const Color(0xFFF59E0B),
                    dark: dark,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MetricTile(
                    title: 'Avg Accuracy',
                    value: total > 0 ? '${avgScore.toStringAsFixed(0)}%' : '—',
                    unit: timeStr,
                    icon: Iconsax.chart_2_copy,
                    accentColor: const Color(0xFF2563EB),
                    dark: dark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── Weekly Activity Footer Banner ───────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: dark
                    ? Colors.white.withValues(alpha: 0.05)
                    : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: dark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Iconsax.info_circle_copy,
                    size: 15,
                    color: streakColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      streakMessage,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: dark ? Colors.white70 : const Color(0xFF334155),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.title,
    required this.value,
    required this.unit,
    required this.icon,
    required this.accentColor,
    required this.dark,
  });

  final String title;
  final String value;
  final String unit;
  final IconData icon;
  final Color accentColor;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: dark ? AppColors.darkContainer : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: dark ? AppColors.darkBorder : const Color(0xFFF1F5F9),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: accentColor),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: dark ? Colors.white60 : AppColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: dark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: dark ? Colors.white54 : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
