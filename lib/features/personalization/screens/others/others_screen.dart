import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:matricmate/common/widgets/appbar/modern_appbar.dart';
import 'package:matricmate/common/widgets/loaders/circular_loading.dart';
import 'package:matricmate/controllers/navigation_controller.dart';
import 'package:matricmate/features/personalization/controllers/analytics_controller.dart';
import 'package:matricmate/features/personalization/controllers/user_controller.dart';
import 'package:matricmate/features/personalization/screens/others/widgets/others_tab_bar.dart';
import 'package:matricmate/features/personalization/screens/others/widgets/pilot_exam_coming_soon.dart';
import 'package:matricmate/features/personalization/screens/others/widgets/progress_view.dart';
import 'package:matricmate/features/personalization/screens/others/widgets/study_plan_coming_soon.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

class OthersScreen extends StatefulWidget {
  const OthersScreen({super.key});

  @override
  State<OthersScreen> createState() => _OthersScreenState();
}

class _OthersScreenState extends State<OthersScreen> {
  late final AnalyticsController controller;
  late final PageController pageController;
  OthersColumn _selectedColumn = OthersColumn.progress;
  Worker? _navWorker;

  @override
  void initState() {
    super.initState();
    controller = Get.isRegistered<AnalyticsController>()
        ? Get.find<AnalyticsController>()
        : Get.put(AnalyticsController());

    pageController = PageController(initialPage: _selectedColumn.index);

    // Instant load when screen is first displayed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.loadAll();
    });

    // Auto-reload whenever user navigates to the Others tab (index 3)
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
    pageController.dispose();
    super.dispose();
  }

  void _onColumnSelected(OthersColumn column) {
    if (_selectedColumn == column) return;
    setState(() {
      _selectedColumn = column;
    });
    if (pageController.hasClients) {
      pageController.animateToPage(
        column.index,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeInOut,
      );
    }
  }

  void _onPageChanged(int index) {
    final column = OthersColumn.values[index];
    if (_selectedColumn != column) {
      setState(() {
        _selectedColumn = column;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = AppHelperFunctions.isDark(context);

    return Scaffold(
      backgroundColor: dark ? AppColors.dark : const Color(0xFFF8FAFC),
      appBar: ModernAppbarWithBuilder(
        title: 'Others',
        subtitleBuilder: (_) => Obx(() {
          final stream = UserController.instance.user.value.stream;
          final label = stream.isNotEmpty
              ? '${stream[0].toUpperCase()}${stream.substring(1)} science stream'
              : 'Matric Hub & Tools';
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
      body: Column(
        children: [
          // ── Top Columns / Tabs Bar ────────────────────────────────────────
          OthersTabBar(
            selectedColumn: _selectedColumn,
            onSelect: _onColumnSelected,
          ),

          // ── Column Pages ─────────────────────────────────────────────────
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const AppCircularLoading(title: 'Loading progress...');
              }

              return PageView(
                controller: pageController,
                physics: const ClampingScrollPhysics(),
                onPageChanged: _onPageChanged,
                children: [
                  // Column 1: Progress (Only necessary metrics, clean & modern)
                  RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: controller.loadAll,
                    child: ProgressView(controller: controller),
                  ),

                  // Column 2: Pilot Exam (Coming soon)
                  const PilotExamComingSoon(),

                  // Column 3: Study Plan (Coming soon)
                  const StudyPlanComingSoon(),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}
