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
              style: TextStyle(
                color: AppColors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '${user.stream.isNotEmpty ? user.stream[0].toUpperCase() + user.stream.substring(1) : ''} science stream',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
        actions: [
          Obx(() {
            final count = controller.activeFilterCount;
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
                if (count > 0)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: const BoxDecoration(
                        color: AppColors.secondary,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '$count',
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
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
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
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
                // Active filter chips row — no Obx needed, parent Obx covers it
                if (controller.hasActiveFilters)
                  ActiveFilterRow(controller: controller),

                AnalyticsSummaryGrid(controller: controller),
                const SizedBox(height: AppSizes.spaceBtwSections),

                ScoreTrendChart(controller: controller),
                const SizedBox(height: AppSizes.spaceBtwSections),

                SubjectPerformanceSection(controller: controller),
                const SizedBox(height: AppSizes.spaceBtwSections),

                TestTypeDistribution(controller: controller),
                const SizedBox(height: AppSizes.spaceBtwSections),

                ChapterProgressSection(controller: controller),
                const SizedBox(height: AppSizes.spaceBtwSections),

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
