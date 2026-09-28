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
              // ── Header Welcome Card ───────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: dark
                        ? [
                            const Color(0xFF0F766E),
                            const Color(0xFF134E4A),
                            const Color(0xFF042F2C),
                          ]
                        : [
                            const Color(0xFF0D9488),
                            const Color(0xFF0F766E),
                            const Color(0xFF115E59),
                          ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0D9488).withValues(alpha: 0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.25),
                          width: 1,
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.stars_rounded, size: 13, color: Color(0xFFFDE047)),
                          SizedBox(width: 4),
                          Text(
                            'MATRIC ADVANCED SUITE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Tools & Exam Prep Hub',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'Access performance analytics, national exam simulations, and personalized study roadmaps.',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Color(0xFFCCFBF1),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              // ── Section Title ─────────────────────────────────────────────
              Text(
                'Available Features',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: dark ? Colors.white : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),

              // ── 1. Analytics & Progress Card ─────────────────────────────
              Obx(() {
                final readiness = controller.holisticReadiness;
                final tests = controller.testsCompleted.value;
                final badge = (tests > 0 || controller.completedNotesCount.value > 0)
                    ? '${readiness.toStringAsFixed(0)}% Ready'
                    : 'View Insights';

                return OthersMenuCard(
                  title: 'Analytics & Progress',
                  description:
                      'Track your matric exam readiness, accuracy percentage, subject mastery, and score trajectory.',
                  icon: Iconsax.chart_2_copy,
                  iconColor: const Color(0xFF10B981),
                  badgeText: badge,
                  badgeColor: const Color(0xFF10B981).withValues(alpha: dark ? 0.22 : 0.12),
                  badgeTextColor: const Color(0xFF10B981),
                  onTap: () => Get.toNamed(Routes.progressDetail),
                );
              }),

              const SizedBox(height: 12),

              // ── 2. Pilot Exam Simulator Card ─────────────────────────────
              OthersMenuCard(
                title: 'Pilot Exam Simulator',
                description:
                    'Simulate real national matric entrance exam conditions under authentic timed rules and rankings.',
                icon: Iconsax.timer_1_copy,
                iconColor: const Color(0xFF0284C7),
                badgeText: 'COMING SOON',
                isBadgeComingSoon: true,
                onTap: () => Get.toNamed(Routes.pilotExam),
              ),

              const SizedBox(height: 12),

              // ── 3. Smart Study Plan Card ─────────────────────────────────
              OthersMenuCard(
                title: 'Smart Study Plan',
                description:
                    'AI-driven daily revision roadmap and spaced repetition built for your target exam date.',
                icon: Iconsax.calendar_tick_copy,
                iconColor: const Color(0xFF8B5CF6),
                badgeText: 'COMING SOON',
                isBadgeComingSoon: true,
                onTap: () => Get.toNamed(Routes.studyPlan),
              ),

              const SizedBox(height: 24),

              // ── Quick Info Tip ───────────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: dark ? AppColors.darkCard : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: dark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
                    width: 1.2,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.lightbulb_outline_rounded,
                          color: AppColors.primary,
                          size: 22,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Daily Exam Preparation Tip',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: dark ? Colors.white : AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Regular practice with short test sessions combined with reading notes produces the highest score gains.',
                            style: TextStyle(
                              fontSize: 12,
                              color: dark ? AppColors.darkGrey : AppColors.textSecondary,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
