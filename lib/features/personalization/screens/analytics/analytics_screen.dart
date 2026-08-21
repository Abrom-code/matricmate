import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matricmate/common/widgets/appbar/modern_appbar.dart';
import 'package:matricmate/features/personalization/controllers/analytics_controller.dart';
import 'package:matricmate/features/personalization/controllers/user_controller.dart';
import 'package:matricmate/features/personalization/screens/analytics/widgets/analytics_filter_sheet.dart';
import 'package:matricmate/features/personalization/screens/analytics/widgets/analytics_summary_grid.dart';
import 'package:matricmate/features/personalization/screens/analytics/widgets/chapter_progress_section.dart';
import 'package:matricmate/features/personalization/screens/analytics/widgets/score_trend_chart.dart';
import 'package:matricmate/features/personalization/screens/analytics/widgets/subject_performance_section.dart';
import 'package:matricmate/features/personalization/screens/analytics/widgets/test_type_distribution.dart';
import 'package:matricmate/features/personalization/screens/analytics/widgets/weakest_areas_card.dart';
import 'package:matricmate/common/widgets/loaders/circular_loading.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/constants/sizes.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  late final AnalyticsController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.put(AnalyticsController());
  }

  @override
  void dispose() {
    Get.delete<AnalyticsController>(force: true);
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
              // Center and constrain content width in landscape
              final content = SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Active filter chips row
                    if (controller.hasActiveFilters) ...[
                      ActiveFilterRow(controller: controller),
                      const SizedBox(height: 12),
                    ],

                    AnalyticsSummaryGrid(controller: controller),
                    const SizedBox(height: 14),

                    ScoreTrendChart(controller: controller),
                    const SizedBox(height: 14),

                    SubjectPerformanceSection(controller: controller),
                    const SizedBox(height: 14),

                    TestTypeDistribution(controller: controller),
                    const SizedBox(height: 14),

                    ChapterProgressSection(controller: controller),
                    const SizedBox(height: 14),

                    WeakestAreasCard(controller: controller),
                    const SizedBox(height: AppSizes.spaceBtwSections),
                  ],
                ),
              );

              if (!isLandscape) return content;

              // Landscape: center and cap width so content stays readable.
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
