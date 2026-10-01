import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matricmate/common/widgets/appbar/modern_appbar.dart';
import 'package:matricmate/common/widgets/appbar/reactive_refresh_button.dart';
import 'package:matricmate/common/widgets/loaders/circular_loading.dart';
import 'package:matricmate/features/personalization/controllers/analytics_controller.dart';
import 'package:matricmate/features/personalization/screens/others/widgets/progress_view.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

class ProgressDetailScreen extends StatefulWidget {
  const ProgressDetailScreen({super.key});

  @override
  State<ProgressDetailScreen> createState() => _ProgressDetailScreenState();
}

class _ProgressDetailScreenState extends State<ProgressDetailScreen> {
  late final AnalyticsController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.isRegistered<AnalyticsController>()
        ? Get.find<AnalyticsController>()
        : Get.put(AnalyticsController());

    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.loadAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    final dark = AppHelperFunctions.isDark(context);

    return Scaffold(
      backgroundColor: dark ? AppColors.dark : const Color(0xFFF8FAFC),
      appBar: ModernAppbar(
        title: 'Analytics & Progress',
        subtitle: 'Performance & Exam Insights',
        showBackArrow: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Obx(
              () => ReactiveRefreshButton(
                isRefreshing: controller.isRefreshing.value,
                onRefresh: () => controller.loadAll(isManualRefresh: true),
                tooltip: 'Refresh analytics',
                onSuccessMessage: 'Analytics & progress updated',
              ),
            ),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const AppCircularLoading(title: 'Loading progress...');
        }

        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () => controller.loadAll(isManualRefresh: true),
          child: ProgressView(controller: controller),
        );
      }),
    );
  }
}
