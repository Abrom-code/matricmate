import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matricmate/common/widgets/appbar/modern_appbar.dart';
import 'package:matricmate/common/widgets/loaders/circular_loading.dart';
import 'package:matricmate/features/exam/controllers/subjects_controller.dart';
import 'package:matricmate/features/exam/controllers/syncing_controller.dart';
import 'package:matricmate/features/exam/screens/entrance/widgets/entrance_subject_tile.dart';
import 'package:matricmate/features/exam/screens/premium/widgets/premium_banner.dart';
import 'package:matricmate/features/exam/screens/premium/widgets/premium_bottom_sheet.dart';
import 'package:matricmate/features/personalization/controllers/user_controller.dart';
import 'package:matricmate/routes/app_routes.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/constants/sizes.dart';

class EntranceScreen extends StatefulWidget {
  const EntranceScreen({super.key});

  @override
  State<EntranceScreen> createState() => _EntranceScreenState();
}

class _EntranceScreenState extends State<EntranceScreen> with RouteAware {
  SubjectsController get ctrl => SubjectsController.instance;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ctrl.loadPausedTests();
      if (mounted) {
        appRouteObserver.subscribe(this, ModalRoute.of(context)!);
      }
    });
  }

  @override
  void dispose() {
    appRouteObserver.unsubscribe(this);
    super.dispose();
  }

  // Refresh banner when the user navigates back to this screen.
  @override
  void didPopNext() => ctrl.loadPausedTests();

  @override
  Widget build(BuildContext context) {
    final syncController = Get.find<SyncingController>();

    return Scaffold(
      appBar: ModernAppbar(
        title: 'Entrance Exams',
        subtitle: 'Select a subject',
        actions: [
          // Paused tests (entrance + model only)
          Obx(() {
            final count = ctrl.pausedTests
                .where((t) => t.testType == 'entrance' || t.testType == 'model')
                .length;
            if (count == 0) return const SizedBox.shrink();
            return IconButton(
              tooltip: '$count test${count == 1 ? '' : 's'} in progress',
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints(),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              onPressed: () => Get.toNamed(
                Routes.pausedTests,
                arguments: {
                  'types': ['entrance', 'model'],
                },
              ),
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(
                    Icons.pause_circle_filled_rounded,
                    size: 20,
                    color: AppColors.white,
                  ),
                  Positioned(
                    top: -5,
                    right: -6,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: AppColors.secondary,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 14,
                        minHeight: 14,
                      ),
                      child: Text(
                        '$count',
                        style: const TextStyle(
                          color: AppColors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          height: 1,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          Obx(() {
            final syncing = syncController.entranceSyncing.value;
            return IconButton(
              tooltip: syncing ? 'Sync in progress…' : 'Sync entrance exams',
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints(),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              onPressed: syncing
                  ? null
                  : () => syncController.syncEntranceExams(),
              icon: syncing
                  ? const SizedBox(
                      width: 24,
                      height: 20,
                      child: Center(
                        child: AppPulsingDots(
                          dotSize: 4,
                          dotSpacing: 2,
                          color: AppColors.white,
                        ),
                      ),
                    )
                  : const Icon(
                      Icons.cloud_sync_outlined,
                      size: 20,
                      color: AppColors.white,
                    ),
            );
          }),
        ],
      ),
      body: Obx(() {
        final subjects = ctrl.filteredSubjects;
        final entranceNums = ctrl.entranceTestNumbers;
        final modelNums = ctrl.modelTestNumbers;
        final syncing = syncController.entranceSyncing.value;
        final isInactive = UserController.instance.user.value.isInactive;

        if (ctrl.isLoading.value && subjects.isEmpty) {
          return const AppCircularLoading(title: 'Loading...');
        }

        if (subjects.isEmpty) {
          return const Center(
            child: Text(
              'No subjects yet.\nTap the sync button on the home screen.',
              textAlign: TextAlign.center,
            ),
          );
        }

        return Stack(
          children: [
            CustomScrollView(
              slivers: [
                // ── Banners ─────────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSizes.defaultSpace,
                      AppSizes.defaultSpace,
                      AppSizes.defaultSpace,
                      0,
                    ),
                    child: Column(
                      children: [
                        // Premium banner (inactive users only)
                        if (isInactive) ...[
                          PremiumBanner(
                            onTap: () => Get.bottomSheet(
                              const PremiumBottomSheet(),
                              isScrollControlled: true,
                            ),
                          ),
                          const SizedBox(height: AppSizes.spaceBtwItems),
                        ],
                      ],
                    ),
                  ),
                ),

                // ── Subject list ─────────────────────────────────────────
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSizes.defaultSpace,
                    AppSizes.spaceBtwItems,
                    AppSizes.defaultSpace,
                    AppSizes.defaultSpace,
                  ),
                  sliver: SliverList.separated(
                    itemCount: subjects.length + 1,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSizes.spaceBtwItems),
                    itemBuilder: (_, index) {
                      if (index == subjects.length) {
                        return const SizedBox(
                          height: AppSizes.spaceBtwSections * 2,
                        );
                      }
                      final subject = subjects[index];
                      final entranceCount = entranceNums[subject.id] ?? 0;
                      final modelCount = modelNums[subject.id] ?? 0;

                      return EntranceSubjectTile(
                        subject: subject,
                        entranceCount: entranceCount,
                        modelCount: modelCount,
                        total: entranceCount + modelCount,
                      );
                    },
                  ),
                ),
              ],
            ),
            if (syncing)
              const Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: LinearProgressIndicator(
                  minHeight: 3,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
          ],
        );
      }),
    );
  }
}
