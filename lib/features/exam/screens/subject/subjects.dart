import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matricmate/common/widgets/appbar/modern_appbar.dart';
import 'package:matricmate/common/widgets/appbar/sync_icon_button.dart';
import 'package:matricmate/common/widgets/exam/premium_bottom_sheet.dart';
import 'package:matricmate/common/widgets/layout/grid_layout.dart';
import 'package:matricmate/common/widgets/loaders/circular_loading.dart';
import 'package:matricmate/features/exam/controllers/subjects_controller.dart';
import 'package:matricmate/features/exam/controllers/syncing_controller.dart';
import 'package:matricmate/features/exam/screens/premium/widgets/pending_payment_banner.dart';
import 'package:matricmate/features/exam/screens/premium/widgets/premium_banner.dart';
import 'package:matricmate/features/exam/screens/subject/widgets/paused_test_banner.dart';
import 'package:matricmate/features/exam/screens/subject/widgets/subject_container.dart';
import 'package:matricmate/features/exam/screens/subject/widgets/subject_mode_modal.dart';
import 'package:matricmate/features/personalization/controllers/user_controller.dart';
import 'package:matricmate/routes/app_routes.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

class SubjectsScreen extends StatefulWidget {
  const SubjectsScreen({super.key});

  @override
  State<SubjectsScreen> createState() => _SubjectsScreenState();
}

class _SubjectsScreenState extends State<SubjectsScreen> with RouteAware {
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
        title: 'MatricET',
        showNotification: true,
        subtitleBuilder: (_) => Obx(() {
          final stream = UserController.instance.user.value.stream;
          if (stream.isEmpty) return const SizedBox.shrink();
          final label =
              '${stream[0].toUpperCase()}${stream.substring(1)} stream';
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
            final syncing = syncController.refreshing.value;
            return SyncIconButton(
              isSyncing: syncing,
              tooltip: 'Sync content',
              onPressed: () => ctrl.syncAll(),
            );
          }),
        ],
      ),
      body: Obx(() {
        final isInactive = UserController.instance.user.value.isInactive;
        final isPending = UserController.instance.user.value.isPending;
        final filteredSubjects = ctrl.filteredSubjects;
        final syncing = syncController.refreshing.value;
        final isOffline = ctrl.isOffline.value;

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
                padding: EdgeInsets.fromLTRB(
                  16,
                  16,
                  16,
                  MediaQuery.paddingOf(context).bottom + 100,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── 1. Pending Payment Banner ────────────────────
                    if (isPending) ...[
                      const PendingPaymentBanner(),
                      const SizedBox(height: 16),
                    ],

                    // ── 2. Upgrade to Premium Banner ─────────────────
                    if (isInactive) ...[
                      PremiumBanner(
                        onTap: () => Get.bottomSheet(
                          const PremiumBottomSheet(),
                          isScrollControlled: true,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // ── 3. Paused / In-Progress Tests Banner ─────────
                    const PausedTestBanner(),

                    // ── 4. Subject Grid ──────────────────────────────
                    if (filteredSubjects.isNotEmpty) ...[
                      GridLayout(
                        mainAxisExtent: 175,
                        itemCount: filteredSubjects.length,
                        itemBuilder: (_, index) {
                          final subject = filteredSubjects[index];
                          final isDownloaded = subject.isDownloaded || subject.isEntranceDownloaded;
                          return SubjectContainer(
                            title: subject.name,
                            image: AppHelperFunctions.getSubjectImage(
                              subject.name,
                            ),
                            isDownloaded: isDownloaded,
                            onPressed: () =>
                                ctrl.downloadSubject(subject.name, subject.id),
                            onTap: () =>
                                SubjectModeModal.show(context, subject),
                            onDelete: isDownloaded
                                ? () => SubjectModeModal.confirmDelete(
                                      context,
                                      subject,
                                    )
                                : null,
                          );
                        },
                      ),
                      const SizedBox(height: 18),
                    ],

                    // ── 5. Empty State ───────────────────────────────
                    if (filteredSubjects.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 48),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isOffline
                                      ? Icons.wifi_off_rounded
                                      : Icons.menu_book_rounded,
                                  size: 40,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                isOffline
                                    ? "You're offline"
                                    : 'No subjects found',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                isOffline
                                    ? 'Subjects will load automatically once '
                                          "you're back online."
                                    : 'Tap the button below to load your '
                                          'stream subjects.',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: AppColors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: () =>
                                    ctrl.ensureSubjectsLoaded(forceRemote: true),
                                icon: const Icon(Icons.sync_rounded, size: 16),
                                label: Text(
                                  isOffline ? 'Retry' : 'Load Subjects',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // ── Top Syncing Indicator ────────────────────────────────
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
