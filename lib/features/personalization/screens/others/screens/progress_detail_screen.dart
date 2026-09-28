import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:matricmate/common/widgets/appbar/modern_appbar.dart';
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
            child: IconButton(
              tooltip: 'Refresh',
              onPressed: () => controller.loadAll(),
              icon: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Iconsax.refresh_copy,
                    size: 17,
                    color: AppColors.white,
                  ),
                ),
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
          onRefresh: controller.loadAll,
          child: ProgressView(controller: controller),
        );
      }),
    );
  }
}
