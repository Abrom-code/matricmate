import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matricmate/common/widgets/appbar/modern_appbar.dart';
import 'package:matricmate/common/widgets/loaders/circular_loading.dart';
import 'package:matricmate/features/exam/controllers/subjects_controller.dart';
import 'package:matricmate/features/exam/controllers/syncing_controller.dart';
import 'package:matricmate/features/exam/screens/entrance/widgets/entrance_subject_tile.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/constants/sizes.dart';

class EntranceScreen extends StatelessWidget {
  EntranceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = SubjectsController.instance;
    final syncController = Get.find<SyncingController>();

    return Scaffold(
      appBar: ModernAppbar(
        title: 'Entrance Exams',
        subtitle: 'Select a subject',
        actions: [
          Obx(() {
            final syncing = syncController.entranceSyncing.value;
            // Also disable while any per-subject entrance download is running
            final anyDownloading = controller.entranceDownloadStep.isNotEmpty;
            final busy = syncing || anyDownloading;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: IconButton(
                tooltip: busy ? 'Download in progress…' : 'Sync entrance exams',
                onPressed: busy
                    ? null
                    : () => syncController.syncEntranceExams(),
                icon: busy
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
        final subjects = controller.filteredSubjects;
        // Explicitly read both maps inside Obx so any count update
        // (from refreshEntranceCountsFromRemote) triggers a rebuild.
        final entranceNums = controller.entranceTestNumbers;
        final modelNums = controller.modelTestNumbers;
        final syncing = syncController.entranceSyncing.value;
        final anyDownloading = controller.entranceDownloadStep.isNotEmpty;
        final busy = syncing || anyDownloading;

        if (controller.isLoading.value && subjects.isEmpty) {
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
            ListView.separated(
              padding: const EdgeInsets.all(AppSizes.defaultSpace),
              itemCount: subjects.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppSizes.spaceBtwItems),
              itemBuilder: (_, index) {
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
            if (busy)
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
