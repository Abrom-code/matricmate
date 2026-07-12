import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matricmate/common/widgets/appbar/modern_appbar.dart';
import 'package:matricmate/common/widgets/layout/grid_layout.dart';
import 'package:matricmate/common/widgets/loaders/circular_loading.dart';
import 'package:matricmate/features/exam/controllers/question_controller.dart';
import 'package:matricmate/features/exam/controllers/subjects_controller.dart';
import 'package:matricmate/features/exam/controllers/syncing_controller.dart';
import 'package:matricmate/features/exam/screens/premium/widgets/pending_payment_banner.dart';
import 'package:matricmate/features/exam/screens/premium/widgets/premium_banner.dart';
import 'package:matricmate/features/exam/screens/premium/widgets/premium_bottom_sheet.dart';
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
    final dark = AppHelperFunctions.isDark(context);
    final progress = total > 0 ? answered / total : 0.0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Get.delete<QuestionController>(force: true);
          Get.toNamed(
            Routes.questions,
            arguments: {
              'test_id': draft.testId,
              'is_timed': false,
              'is_exam_mode': false,
              'time': testTime,
              'id': -1, // no parent controller to refresh on this path
              'draft': draft,
            },
          );
        },
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: dark ? 0.15 : 0.09),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.orange.withValues(alpha: 0.45)),
          ),
          child: Row(
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.orange.shade700,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),

              // Text + progress bar
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            testTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.orange.shade800,
                            ),
                          ),
                        ),
                        Text(
                          '$answered/$total',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress.clamp(0.0, 1.0),
                        minHeight: 5,
                        backgroundColor: Colors.orange.withValues(alpha: 0.18),
                        color: Colors.orange.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap to continue',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.orange.shade600,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 13,
                color: Colors.orange.shade600,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
