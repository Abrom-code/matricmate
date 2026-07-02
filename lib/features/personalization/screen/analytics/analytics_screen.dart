import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matricmate/common/widgets/appbar/appbar.dart';
import 'package:matricmate/features/exam/screens/subject/widgets/app_drawer.dart';
import 'package:matricmate/features/personalization/controller/analytics_controller.dart';
import 'package:matricmate/features/personalization/controller/user_controller.dart';
import 'package:matricmate/features/personalization/screen/analytics/widgets/analytics_filter_sheet.dart';
import 'package:matricmate/features/personalization/screen/analytics/widgets/analytics_summary_grid.dart';
import 'package:matricmate/features/personalization/screen/analytics/widgets/chapter_progress_section.dart';
import 'package:matricmate/features/personalization/screen/analytics/widgets/score_trend_chart.dart';
import 'package:matricmate/features/personalization/screen/analytics/widgets/subject_performance_section.dart';
import 'package:matricmate/features/personalization/screen/analytics/widgets/test_type_distribution.dart';
import 'package:matricmate/features/personalization/screen/analytics/widgets/weakest_areas_card.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/constants/sizes.dart';

class AnalyticsScreen extends StatelessWidget {
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AnalyticsController());
    final user = UserController.instance.user.value;

    return Scaffold(
      key: scaffoldKey,
      drawer: const AppDrawer(),
      appBar: Appbar(
        leadingIcon: Icons.menu,
        leadingOnPressed: () => scaffoldKey.currentState?.openDrawer(),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Analytics',
              style: TextStyle(color: AppColors.white, fontSize: 18, fontWeight: FontWeight.w600),
            ),
            Text(
              '${user.stream.isNotEmpty ? user.stream[0].toUpperCase() + user.stream.substring(1) : ''} science stream',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
        actions: [
          Obx(() {
            final active = controller.hasActiveFilters;
            return Stack(
              alignment: Alignment.topRight,
              children: [
                IconButton(
                  icon: const Icon(Icons.tune_outlined, color: AppColors.white),
                  onPressed: () => Get.bottomSheet(
                    AnalyticsFilterSheet(controller: controller),
                    isScrollControlled: true,
                  ),
                ),
                if (active)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.secondary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            );
          }),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }
        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: controller.loadAll,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppSizes.defaultSpace),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Active filter chips row
                Obx(() {
                  if (!controller.hasActiveFilters) return const SizedBox.shrink();
                  return _ActiveFilterRow(controller: controller);
                }),

                // 1 — Summary cards
                AnalyticsSummaryGrid(controller: controller),
                const SizedBox(height: AppSizes.spaceBtwSections),

                // 2 — Score trend
                ScoreTrendChart(controller: controller),
                const SizedBox(height: AppSizes.spaceBtwSections),

                // 3 — Performance by subject
                SubjectPerformanceSection(controller: controller),
                const SizedBox(height: AppSizes.spaceBtwSections),

                // 4 — Test type distribution
                TestTypeDistribution(controller: controller),
                const SizedBox(height: AppSizes.spaceBtwSections),

                // 5 — Chapter progress
                ChapterProgressSection(controller: controller),
                const SizedBox(height: AppSizes.spaceBtwSections),

                // 6 — Weakest areas
                WeakestAreasCard(controller: controller),
                const SizedBox(height: AppSizes.spaceBtwSections),
              ],
            ),
          ),
        );
      }),
    );
  }
}

/// Scrollable row of dismissible chips for active filters
class _ActiveFilterRow extends StatelessWidget {
  const _ActiveFilterRow({required this.controller});
  final AnalyticsController controller;

  static const _timeLabels = {
    TimeFilter.all: 'All time',
    TimeFilter.lastWeek: 'Last 7 days',
    TimeFilter.lastMonth: 'Last 30 days',
    TimeFilter.last3Months: 'Last 3 months',
  };

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[];

    final subject = controller.selectedSubject.value;
    if (subject != null && subject != 'All Subjects') {
      chips.add(_FilterChip(
        label: subject,
        onRemove: () => controller.applyFilters(subject: 'All Subjects'),
      ));
    }

    final type = controller.selectedTestType.value;
    if (type != null && type != 'All Types') {
      chips.add(_FilterChip(
        label: type,
        onRemove: () => controller.applyFilters(testType: 'All Types'),
      ));
    }

    final tf = controller.selectedTimeFilter.value;
    if (tf != TimeFilter.all) {
      chips.add(_FilterChip(
        label: _timeLabels[tf]!,
        onRemove: () => controller.applyFilters(timeFilter: TimeFilter.all),
      ));
    }

    chips.add(
      GestureDetector(
        onTap: controller.resetFilters,
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: Text(
            'Clear all',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.error,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.spaceBtwItems),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: chips.map((c) => Padding(
          padding: const EdgeInsets.only(right: 6),
          child: c,
        )).toList()),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.onRemove});
  final String label;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(Icons.close, size: 14, color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}
