import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matricmate/features/personalization/controllers/analytics_controller.dart';
import 'package:matricmate/features/personalization/screens/analytics/widgets/analytics_summary_grid.dart';
import 'package:matricmate/features/personalization/screens/analytics/widgets/score_trend_chart.dart';
import 'package:matricmate/features/personalization/screens/analytics/widgets/subject_performance_section.dart';
import 'package:matricmate/features/personalization/screens/analytics/widgets/weakest_areas_card.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

class ProgressView extends StatelessWidget {
  const ProgressView({super.key, required this.controller});

  final AnalyticsController controller;

  @override
  Widget build(BuildContext context) {
    final dark = AppHelperFunctions.isDark(context);

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        MediaQuery.paddingOf(context).bottom + 90,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Quick Period Filter Selector ──────────────────────────────────
          Obx(() {
            final selected = controller.selectedTimeFilter.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: dark ? AppColors.darkCard : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: dark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: dark ? 0.2 : 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  _PeriodFilterPill(
                    title: 'All Time',
                    isSelected: selected == TimeFilter.all,
                    onTap: () => controller.applyFilters(timeFilter: TimeFilter.all),
                    dark: dark,
                  ),
                  _PeriodFilterPill(
                    title: 'Last 30 Days',
                    isSelected: selected == TimeFilter.lastMonth,
                    onTap: () => controller.applyFilters(timeFilter: TimeFilter.lastMonth),
                    dark: dark,
                  ),
                  _PeriodFilterPill(
                    title: 'Last 7 Days',
                    isSelected: selected == TimeFilter.lastWeek,
                    onTap: () => controller.applyFilters(timeFilter: TimeFilter.lastWeek),
                    dark: dark,
                  ),
                ],
              ),
            );
          }),

          // ── 1. Hero Readiness & 4 Key Metrics Grid ────────────────────────
          AnalyticsSummaryGrid(controller: controller),

          // ── 2. Weakest Areas / Recommended Focus (if detected) ───────────
          Obx(() {
            if (controller.weakestAreas.isNotEmpty) {
              return Column(
                children: [
                  const SizedBox(height: 14),
                  WeakestAreasCard(controller: controller),
                ],
              );
            }
            return const SizedBox.shrink();
          }),

          // ── 3. Subject Mastery Breakdown ──────────────────────────────────
          const SizedBox(height: 14),
          SubjectPerformanceSection(controller: controller),

          // ── 4. Score Trajectory Trend ──────────────────────────────────────
          Obx(() {
            if (controller.trendPoints.isNotEmpty || controller.testsCompleted.value > 0) {
              return Column(
                children: [
                  const SizedBox(height: 14),
                  ScoreTrendChart(controller: controller),
                ],
              );
            }
            return const SizedBox.shrink();
          }),
        ],
      ),
    );
  }
}

class _PeriodFilterPill extends StatelessWidget {
  const _PeriodFilterPill({
    required this.title,
    required this.isSelected,
    required this.onTap,
    required this.dark,
  });

  final String title;
  final bool isSelected;
  final VoidCallback onTap;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              color: isSelected
                  ? Colors.white
                  : (dark ? AppColors.darkGrey : AppColors.textSecondary),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}
