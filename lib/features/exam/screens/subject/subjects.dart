import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matricmate/common/widgets/appbar/modern_appbar.dart';
import 'package:matricmate/common/widgets/appbar/sync_icon_button.dart';
import 'package:matricmate/common/widgets/layout/grid_layout.dart';
import 'package:matricmate/common/widgets/loaders/circular_loading.dart';
import 'package:matricmate/features/exam/controllers/subjects_controller.dart';
import 'package:matricmate/features/exam/controllers/syncing_controller.dart';
import 'package:matricmate/features/exam/screens/premium/widgets/pending_payment_banner.dart';
import 'package:matricmate/features/exam/screens/premium/widgets/premium_banner.dart';
import 'package:matricmate/common/widgets/exam/premium_bottom_sheet.dart';
import 'package:matricmate/features/exam/screens/subject/widgets/subject_container.dart';
import 'package:matricmate/features/personalization/controllers/user_controller.dart';
import 'package:matricmate/routes/app_routes.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/constants/sizes.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

class SubjectsScreen extends StatefulWidget {
  SubjectsScreen({super.key});

  @override
  State<SubjectsScreen> createState() => _SubjectsScreenState();
}

class _SubjectsScreenState extends State<SubjectsScreen>
    with RouteAware {
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

  // Refresh banner whenever the user navigates back to this screen.
  @override
  void didPopNext() => ctrl.loadPausedTests();

  @override
  Widget build(BuildContext context) {
    final syncController = Get.find<SyncingController>();

    return Scaffold(
      appBar: ModernAppbarWithBuilder(
        title: 'MatricMate',
        showNotification: true,
        subtitleBuilder: (_) => Obx(() {
          final stream = UserController.instance.user.value.stream;
          if (stream.isEmpty) return const SizedBox.shrink();
          final label =
              '${stream[0].toUpperCase()}${stream.substring(1)} stream';
          return Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          );
        }),
        actions: [
          Obx(() {
            final syncing = syncController.refreshing.value;
            return SyncIconButton(
              isSyncing: syncing,
              tooltip: 'Sync content',
              onPressed: () => ctrl.syncAll(),
            );
          }),
          // Paused tests appbar button
          Obx(() {
            final count = ctrl.pausedTests.length;
            if (count == 0) return const SizedBox.shrink();
            return IconButton(
              tooltip: '$count test${count == 1 ? '' : 's'} in progress',
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints(),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              onPressed: () => Get.toNamed(Routes.pausedTests),
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
        ],
      ),
      body: Obx(() {
        final isInactive = UserController.instance.user.value.isInactive;
        final isPending = UserController.instance.user.value.isPending;
        final filteredSubjects = ctrl.filteredSubjects;
        final syncing = syncController.refreshing.value;

        if (filteredSubjects.isEmpty && ctrl.isLoading.value) {
          return const AppCircularLoading(title: 'Loading subjects...');
        }

        return Stack(
          children: [
            RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () async {
                await syncController.syncAll(showUiLoading: false);
                await ctrl.loadPausedTests();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(AppSizes.defaultSpace),
                  child: Column(
                    children: [
                      if (isInactive)
                        PremiumBanner(
                          onTap: () => Get.bottomSheet(
                            const PremiumBottomSheet(),
                            isScrollControlled: true,
                          ),
                        ),
                      if (isInactive)
                        const SizedBox(height: AppSizes.spaceBtwItems),
                      if (isPending) const PendingPaymentBanner(),
                      if (isPending)
                        const SizedBox(height: AppSizes.spaceBtwItems),

                      GridLayout(
                        itemCount: filteredSubjects.length,
                        itemBuilder: (_, index) {
                          final subject = filteredSubjects[index];
                          return SubjectContainer(
                            title: subject.name,
                            image: AppHelperFunctions.getSubjectImage(
                              subject.name,
                            ),
                            isDownloaded: subject.isDownloaded,
                            onPressed: () =>
                                ctrl.downloadSubject(subject.name, subject.id),
                            onTap: () => subject.isDownloaded
                                ? Get.toNamed(
                                    Routes.chapter,
                                    arguments: {
                                      'title': subject.name,
                                      'id': subject.id,
                                    },
                                  )
                                : null,
                          );
                        },
                      ),
                      if (filteredSubjects.isNotEmpty)
                        const SizedBox(height: AppSizes.spaceBtwSections * 2),
                      if (filteredSubjects.isEmpty)
                        const Padding(
                          padding: EdgeInsets.only(
                            top: AppSizes.spaceBtwSections,
                          ),
                          child: Center(
                            child: Text(
                              'No subjects yet.\nTap the sync button to load your content.',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
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
