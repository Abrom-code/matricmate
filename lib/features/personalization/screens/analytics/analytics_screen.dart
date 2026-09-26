import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matricmate/common/widgets/appbar/modern_appbar.dart';
import 'package:matricmate/common/widgets/loaders/circular_loading.dart';
import 'package:matricmate/controllers/navigation_controller.dart';
import 'package:matricmate/features/personalization/controllers/analytics_controller.dart';
import 'package:matricmate/features/personalization/controllers/user_controller.dart';
import 'package:matricmate/features/personalization/screens/analytics/widgets/analytics_filter_sheet.dart';
import 'package:matricmate/features/personalization/screens/analytics/widgets/analytics_summary_grid.dart';
import 'package:matricmate/features/personalization/screens/analytics/widgets/challenge_analytics_section.dart';
import 'package:matricmate/features/personalization/screens/analytics/widgets/chapter_progress_section.dart';
import 'package:matricmate/features/personalization/screens/analytics/widgets/notes_progress_section.dart';
import 'package:matricmate/features/personalization/screens/analytics/widgets/score_trend_chart.dart';
import 'package:matricmate/features/personalization/screens/analytics/widgets/subject_performance_section.dart';
import 'package:matricmate/features/personalization/screens/analytics/widgets/test_type_distribution.dart';
import 'package:matricmate/features/personalization/screens/analytics/widgets/weakest_areas_card.dart';
import 'package:matricmate/features/personalization/screens/analytics/widgets/weakness_action_plan_section.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  late final AnalyticsController controller;
  Worker? _navWorker;

  @override
  void initState() {
    super.initState();
    controller = Get.isRegistered<AnalyticsController>()
        ? Get.find<AnalyticsController>()
        : Get.put(AnalyticsController());

    // Instant load when screen is first displayed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.loadAll();
    });

    // Auto-reload instantly whenever user navigates to the Analytics tab (index 3)
    if (Get.isRegistered<NavigationController>()) {
      _navWorker = ever(NavigationController.instance.selectedIdx, (index) {
        if (index == 3) {
          controller.loadAll();
        }
      });
    }
  }

  @override
  void dispose() {
    _navWorker?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = AppHelperFunctions.isDark(context);

    return Scaffold(
      backgroundColor: dark ? AppColors.dark : const Color(0xFFF8FAFC),
      appBar: ModernAppbarWithBuilder(
        title: 'Analytics',
        subtitleBuilder: (_) => Obx(() {
          final stream = UserController.instance.user.value.stream;
          final label = stream.isNotEmpty
              ? '${stream[0].toUpperCase()}${stream.substring(1)} science stream'
              : 'Performance & Insights';
          return Text(
            label,
            style: const TextStyle(
              color: Color(0xFFD1FAE5),
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
            ),
          );
        }),
        actions: [
          Obx(() {
            final count = controller.activeFilterCount;
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.topRight,
                children: [
                  IconButton(
                    tooltip: 'Filter analytics',
                    onPressed: () => Get.bottomSheet(
                      AnalyticsFilterSheet(controller: controller),
                      isScrollControlled: true,
                    ),
                    icon: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: AppColors.white.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.tune_rounded,
                          size: 17,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                  ),
                  if (count > 0)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: AppColors.secondary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 3,
                            ),
                          ],
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Center(
                          child: Text(
                            '$count',
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: AppColors.black,
                              height: 1,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          }),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const AppCircularLoading(title: 'Loading analytics...');
        }
        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: controller.loadAll,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isLandscape =
                  MediaQuery.orientationOf(context) == Orientation.landscape;

              final content = SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  16,
                  16,
                  16,
                  MediaQuery.paddingOf(context).bottom + 100,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Quick Period Filter Selector ────────────────────────
                    Obx(() {
                      final selected = controller.selectedTimeFilter.value;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: dark ? AppColors.darkCard : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: dark
                                ? AppColors.darkBorder
                                : const Color(0xFFE2E8F0),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(
                                alpha: dark ? 0.2 : 0.03,
                              ),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            _PeriodTab(
                              title: 'All Time',
                              isSelected: selected == TimeFilter.all,
                              onTap: () => controller.applyFilters(
                                timeFilter: TimeFilter.all,
                              ),
                              dark: dark,
                            ),
                            _PeriodTab(
                              title: '30 Days',
                              isSelected: selected == TimeFilter.lastMonth,
                              onTap: () => controller.applyFilters(
                                timeFilter: TimeFilter.lastMonth,
                              ),
                              dark: dark,
                            ),
                            _PeriodTab(
                              title: '7 Days',
                              isSelected: selected == TimeFilter.lastWeek,
                              onTap: () => controller.applyFilters(
                                timeFilter: TimeFilter.lastWeek,
                              ),
                              dark: dark,
                            ),
                          ],
                        ),
                      );
                    }),

                    // Active filter chips row (if any other filters applied)
                    if (controller.hasActiveFilters) ...[
                      ActiveFilterRow(controller: controller),
                      const SizedBox(height: 12),
                    ],

                    // ── Section Tabs Bar ────────────────────────────────────
                    Obx(() {
                      final currentTab = controller.selectedTab.value;
                      final weakCount = controller.weakestAreas.length;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: dark ? AppColors.darkCard : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: dark
                                ? AppColors.darkBorder
                                : const Color(0xFFE2E8F0),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(
                                alpha: dark ? 0.2 : 0.03,
                              ),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            _SectionTab(
                              icon: Icons.dashboard_outlined,
                              title: 'Overview',
                              isSelected: currentTab == AnalyticsTab.overview,
                              onTap: () =>
                                  controller.switchTab(AnalyticsTab.overview),
                              dark: dark,
                            ),
                            _SectionTab(
                              icon: Icons.track_changes_rounded,
                              title: 'Weaknesses',
                              isSelected: currentTab == AnalyticsTab.weaknesses,
                              badgeCount: weakCount,
                              onTap: () =>
                                  controller.switchTab(AnalyticsTab.weaknesses),
                              dark: dark,
                            ),
                            _SectionTab(
                              icon: Icons.menu_book_outlined,
                              title: 'Notes',
                              isSelected: currentTab == AnalyticsTab.notes,
                              onTap: () =>
                                  controller.switchTab(AnalyticsTab.notes),
                              dark: dark,
                            ),
                            _SectionTab(
                              icon: Icons.bar_chart_rounded,
                              title: 'Tests',
                              isSelected: currentTab == AnalyticsTab.tests,
                              onTap: () =>
                                  controller.switchTab(AnalyticsTab.tests),
                              dark: dark,
                            ),
                          ],
                        ),
                      );
                    }),

                    // ── Tab Content Views ───────────────────────────────────
                    Obx(() {
                      switch (controller.selectedTab.value) {
                        case AnalyticsTab.overview:
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 1. Hero Readiness & 4 KPI Stats
                              AnalyticsSummaryGrid(controller: controller),
                              const SizedBox(height: 14),

                              // 2. Focus Alert (if weaknesses detected)
                              WeakestAreasCard(controller: controller),
                              if (controller.weakestAreas.isNotEmpty)
                                const SizedBox(height: 14),

                              // 3. Score Trajectory Trend Chart
                              ScoreTrendChart(controller: controller),
                              const SizedBox(height: 14),

                              // 4. Challenge Arena Analytics
                              ChallengeAnalyticsSection(controller: controller),
                            ],
                          );

                        case AnalyticsTab.weaknesses:
                          return WeaknessActionPlanSection(
                            controller: controller,
                          );

                        case AnalyticsTab.notes:
                          return NotesProgressSection(controller: controller);

                        case AnalyticsTab.tests:
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 1. Subject Mastery Breakdown
                              SubjectPerformanceSection(controller: controller),
                              const SizedBox(height: 14),

                              // 2. Test Type Distribution
                              TestTypeDistribution(controller: controller),
                              const SizedBox(height: 14),

                              // 3. Chapter Progress Section
                              ChapterProgressSection(controller: controller),
                            ],
                          );
                      }
                    }),
                  ],
                ),
              );

              if (!isLandscape) return content;

              // Landscape: center and cap width
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: content,
                ),
              );
            },
          ),
        );
      }),
    );
  }
}

class _SectionTab extends StatelessWidget {
  const _SectionTab({
    required this.icon,
    required this.title,
    required this.isSelected,
    required this.onTap,
    required this.dark,
    this.badgeCount = 0,
  });

  final IconData icon;
  final String title;
  final bool isSelected;
  final VoidCallback onTap;
  final bool dark;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 14.5,
                color: isSelected
                    ? Colors.white
                    : (dark ? AppColors.darkGrey : AppColors.textSecondary),
              ),
              const SizedBox(width: 3),
              Flexible(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: isSelected
                        ? Colors.white
                        : (dark ? AppColors.darkGrey : AppColors.textSecondary),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (badgeCount > 0 && !isSelected) ...[
                const SizedBox(width: 3),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$badgeCount',
                    style: const TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFEF4444),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PeriodTab extends StatelessWidget {
  const _PeriodTab({
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
