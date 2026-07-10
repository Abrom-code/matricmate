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
import 'package:matricmate/features/exam/screens/subject/widgets/subject_container.dart';
import 'package:matricmate/features/personalization/controller/user_controller.dart';
import 'package:matricmate/routes/app_routes.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/constants/sizes.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

class SubjectsScreen extends StatelessWidget {
  SubjectsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final subjectController = SubjectsController.instance;
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
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 8),
                _StatusBadge(status: user.status),
              ] else
                _StatusBadge(status: user.status),
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
                onPressed: syncing ? null : () => subjectController.syncAll(),
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
        final filteredSubjects = subjectController.filteredSubjects;

        // Show loading only when subjects haven't loaded from local DB yet
        if (filteredSubjects.isEmpty && subjectController.isLoading.value) {
          return const AppCircularLoading(title: 'Loading subjects...');
        }

        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.defaultSpace),
            child: Column(
              children: [
                if (isInactive)
                  PremiumBanner(
                    onTap: () {
                      Get.bottomSheet(
                        const PremiumBottomSheet(),
                        isScrollControlled: true,
                      );
                    },
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
                      onPressed: () => subjectController.downloadSubject(
                        subject.name,
                        subject.id,
                      ),
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

// ── Status badge ──────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case 'active':
        return _GoldPremiumBadge();
      case 'pending':
        return _PendingBadge();
      default:
        return _FreeBadge();
    }
  }
}

/// Gold gradient pill with a star — shown for premium users.
class _GoldPremiumBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFD700), Color(0xFFFFA000)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD700).withValues(alpha: 0.4),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, size: 11, color: Colors.white),
          SizedBox(width: 3),
          Text(
            'PREMIUM',
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// Amber pill with a clock — shown while payment is pending.
class _PendingBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.amber, width: 1),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.access_time_rounded, size: 11, color: Colors.amber),
          SizedBox(width: 3),
          Text(
            'PENDING',
            style: TextStyle(
              color: Colors.amber,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// Subtle teal outline pill — shown for free users (low emphasis).
class _FreeBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: const Text(
        'FREE',
        style: TextStyle(
          color: Colors.white70,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
