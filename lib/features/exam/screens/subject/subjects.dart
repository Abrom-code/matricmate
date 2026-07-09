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

          Color statusColor;
          String statusText;
          switch (user.status) {
            case 'active':
              statusColor = AppColors.success;
              statusText = 'PREMIUM';
              break;
            case 'pending':
              statusColor = Colors.amber;
              statusText = 'PENDING';
              break;
            default:
              statusColor = AppColors.primary.withValues(alpha: 0.6);
              statusText = 'FREE';
          }

          return Row(
            children: [
              if (stream.isNotEmpty)
                Text(
                  stream,
                  style: const TextStyle(color: AppColors.darkGrey, fontSize: 12),
                ),
              if (stream.isNotEmpty) const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
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
                icon: const Icon(
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
        if (UserController.instance.userFetching.value ||
            subjectController.isLoading.value ||
            syncController.refreshing.value) {
          return const AppCircularLoading(title: 'Loading...');
        }

        final isInactive = UserController.instance.user.value.isInactive;
        final isPending = UserController.instance.user.value.isPending;

        final filteredSubjects = subjectController.filteredSubjects;

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
