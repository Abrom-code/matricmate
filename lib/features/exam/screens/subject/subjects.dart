import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matricmate/common/widgets/appbar/modern_appbar.dart';
import 'package:matricmate/common/widgets/layout/grid_layout.dart';
import 'package:matricmate/common/widgets/loaders/circular_loading.dart';
import 'package:matricmate/features/exam/controllers/subjects_controller.dart';
import 'package:matricmate/features/exam/controllers/syncing_controller.dart';
import 'package:matricmate/features/exam/screens/premium/widgets/pending_payment_banner.dart';
import 'package:matricmate/features/exam/screens/premium/widgets/premium_banner.dart';
import 'package:matricmate/features/exam/screens/premium/widgets/premium_bottom_sheet.dart';
import 'package:matricmate/features/exam/screens/ready/ready.dart';
import 'package:matricmate/features/exam/screens/subject/widgets/status_badge.dart';
import 'package:matricmate/features/exam/screens/subject/widgets/subject_container.dart';
import 'package:matricmate/features/personalization/controller/user_controller.dart';
import 'package:matricmate/routes/app_routes.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/constants/sizes.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

class SubjectsScreen extends StatefulWidget {
  SubjectsScreen({super.key});

  @override
  State<SubjectsScreen> createState() => _SubjectsScreenState();
}

class _SubjectsScreenState extends State<SubjectsScreen> with RouteAware {
  SubjectsController get ctrl => SubjectsController.instance;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ctrl.loadInProgressBanner();
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
  void didPopNext() => ctrl.loadInProgressBanner();

  @override
  Widget build(BuildContext context) {
    final syncController = Get.find<SyncingController>();

    return Scaffold(
      appBar: ModernAppbarWithBuilder(
        title: 'MatricMate',
        subtitleBuilder: (_) => Obx(() {
          final user = UserController.instance.user.value;
          final stream = user.stream.isNotEmpty
              ? '${user.stream[0].toUpperCase()}${user.stream.substring(1)} stream'
              : '';

          return Row(
            children: [
              if (stream.isNotEmpty) ...[
                Text(
                  stream,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(width: 8),
                StatusBadge(status: user.status),
              ] else
                StatusBadge(status: user.status),
            ],
          );
        }),
        actions: [
          Obx(() {
            final syncing = syncController.refreshing.value;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: IconButton(
                tooltip: 'Sync content',
                onPressed: syncing ? null : () => ctrl.syncAll(),
                icon: syncing
                    ? const SizedBox(
                        width: 24,
                        height: 24,
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
                        size: AppSizes.iconMd * 1.2,
                        color: AppColors.white,
                      ),
              ),
            );
          }),
        ],
      ),
      body: Obx(() {
        final isInactive = UserController.instance.user.value.isInactive;
        final isPending = UserController.instance.user.value.isPending;
        final filteredSubjects = ctrl.filteredSubjects;

        if (filteredSubjects.isEmpty && ctrl.isLoading.value) {
          return const AppCircularLoading(title: 'Loading subjects...');
        }

        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.defaultSpace),
            child: Column(
              children: [
                // ── Resume banner ──────────────────────────────────────
                Obx(() {
                  final draft = ctrl.inProgressDraft.value;
                  if (draft == null) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(
                      bottom: AppSizes.spaceBtwItems,
                    ),
                    child: _ResumeBanner(
                      testTitle: ctrl.inProgressTestTitle.value,
                      answered: draft.selectedAnswers.length,
                      total: draft.testQuestions.length,
                      draft: draft,
                      testTime: ctrl.inProgressTestTime.value,
                    ),
                  );
                }),

                if (isInactive)
                  PremiumBanner(
                    onTap: () => Get.bottomSheet(
                      const PremiumBottomSheet(),
                      isScrollControlled: true,
                    ),
                  ),
                if (isInactive) const SizedBox(height: AppSizes.spaceBtwItems),

                if (isPending) const PendingPaymentBanner(),
                if (isPending) const SizedBox(height: AppSizes.spaceBtwItems),

                GridLayout(
                  itemCount: filteredSubjects.length,
                  itemBuilder: (_, index) {
                    final subject = filteredSubjects[index];
                    return SubjectContainer(
                      title: subject.name,
                      image: AppHelperFunctions.getSubjectImage(subject.name),
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

                if (filteredSubjects.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: AppSizes.spaceBtwSections),
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
        );
      }),
    );
  }
}

// ── Resume Banner ─────────────────────────────────────────────────────────────

class _ResumeBanner extends StatelessWidget {
  const _ResumeBanner({
    required this.testTitle,
    required this.answered,
    required this.total,
    required this.draft,
    required this.testTime,
  });

  final String testTitle;
  final int answered;
  final int total;
  final dynamic draft; // ResultModel
  final int testTime;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final progress = total > 0 ? answered / total : 0.0;
    final pct = (progress * 100).round();

    // Indigo accent — distinct from teal primary, works in light and dark
    const accentColor = Colors.indigo;

    return Material(
      color: cs.surfaceContainerHighest.withValues(alpha: 0.55),
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Get.dialog(
          ReadyDialog(
            qnCount: total,
            time: testTime,
            testId: draft.testId,
            id: -1,
            draft: draft,
          ),
        ),
        child: Row(
          children: [
            // Left accent stripe
            Container(width: 4, height: 72, color: accentColor),

            const SizedBox(width: 14),

            // Play icon
            const Icon(
              Icons.pause_circle_filled_rounded,
              color: accentColor,
              size: 28,
            ),

            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Label row
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'IN PROGRESS',
                            style: tt.labelSmall?.copyWith(
                              color: accentColor,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.6,
                              fontSize: 9,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '$pct%',
                          style: tt.labelSmall?.copyWith(
                            color: accentColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),

                    // Test title
                    Text(
                      testTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: tt.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Progress bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress.clamp(0.0, 1.0),
                        minHeight: 4,
                        backgroundColor: accentColor.withValues(alpha: 0.15),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          accentColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),

                    Text(
                      '$answered of $total questions answered',
                      style: tt.labelSmall?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Icon(
                Icons.chevron_right_rounded,
                color: cs.onSurface.withValues(alpha: 0.35),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
