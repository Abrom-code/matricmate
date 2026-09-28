import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:matricmate/common/widgets/appbar/modern_appbar.dart';
import 'package:matricmate/controllers/navigation_controller.dart';
import 'package:matricmate/features/personalization/controllers/analytics_controller.dart';
import 'package:matricmate/features/personalization/controllers/user_controller.dart';
import 'package:matricmate/features/personalization/screens/others/widgets/others_menu_card.dart';
import 'package:matricmate/routes/app_routes.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

class OthersScreen extends StatefulWidget {
  const OthersScreen({super.key});

  @override
  State<OthersScreen> createState() => _OthersScreenState();
}

class _OthersScreenState extends State<OthersScreen> {
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
    super.dispose();
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
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: controller.loadAll,
        child: SingleChildScrollView(
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
              // ── 1. Analytics & Progress Card ─────────────────────────────
              OthersMenuCard(
                title: 'Analytics & Progress',
                description:
                    'Track exam readiness, subject mastery & score trends.',
                icon: Iconsax.chart_2_copy,
                iconColor: const Color(0xFF10B981),
                onTap: () => Get.toNamed(Routes.progressDetail),
              ),

              const SizedBox(height: 12),

              // ── 2. Pilot Exam Simulator Card ─────────────────────────────
              OthersMenuCard(
                title: 'Pilot Exam Simulator',
                description:
                    'Simulate real national exams under timed conditions.',
                icon: Iconsax.timer_1_copy,
                iconColor: const Color(0xFF0284C7),
                badgeText: 'PRO',
                badgeColor: const Color(0xFFF59E0B).withValues(alpha: dark ? 0.22 : 0.15),
                badgeTextColor: const Color(0xFFD97706),
                onTap: () => Get.toNamed(Routes.pilotExam),
              ),

              const SizedBox(height: 12),

              // ── 3. Saved Bookmarks Card ──────────────────────────────────
              OthersMenuCard(
                title: 'Bookmarks',
                description:
                    'Review your saved challenging questions and notes.',
                icon: Iconsax.archive_tick_copy,
                iconColor: const Color(0xFFF59E0B),
                onTap: () => Get.toNamed(Routes.bookmark),
              ),

              const SizedBox(height: 12),

              // ── 4. Smart Study Plan Card ─────────────────────────────────
              OthersMenuCard(
                title: 'Smart Study Plan',
                description:
                    'Personalized daily study roadmap for your target score.',
                icon: Iconsax.calendar_tick_copy,
                iconColor: const Color(0xFF8B5CF6),
                badgeText: 'SOON',
                badgeColor: const Color(0xFF8B5CF6).withValues(alpha: dark ? 0.22 : 0.12),
                badgeTextColor: const Color(0xFF8B5CF6),
                onTap: () => Get.toNamed(Routes.studyPlan),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
