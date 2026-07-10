import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:matricmate/common/widgets/appbar/modern_appbar.dart';
import 'package:matricmate/common/widgets/loaders/circular_loading.dart';
import 'package:matricmate/features/exam/controllers/subjects_controller.dart';
import 'package:matricmate/features/exam/controllers/syncing_controller.dart';
import 'package:matricmate/features/exam/models/subject_model.dart';
import 'package:matricmate/routes/app_routes.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/constants/sizes.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

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
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: IconButton(
                tooltip: 'Sync entrance exams',
                onPressed:
                    syncing ? null : () => syncController.syncEntranceExams(),
                icon: syncing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.white,
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
        if (controller.isLoading.value) {
          return const AppCircularLoading(title: 'Loading...');
        }

        final subjects = controller.filteredSubjects;

        // Still syncing on first launch — subjects haven't arrived yet
        if (subjects.isEmpty && syncController.refreshing.value) {
          return const AppCircularLoading(title: 'Loading subjects...');
        }

        if (subjects.isEmpty) {
          return const Center(
            child: Text(
              'No subjects yet.\nTap the sync button on the home screen.',
              textAlign: TextAlign.center,
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(AppSizes.defaultSpace),
          itemCount: subjects.length,
          separatorBuilder: (_, __) =>
              const SizedBox(height: AppSizes.spaceBtwItems),
          itemBuilder: (_, index) {
            final subject = subjects[index];
            final entranceCount =
                controller.entranceTestNumbers[subject.id] ?? 0;
            final modelCount = controller.modelTestNumbers[subject.id] ?? 0;
            final total = entranceCount + modelCount;

            return _EntranceSubjectTile(
              subject: subject,
              entranceCount: entranceCount,
              modelCount: modelCount,
              total: total,
            );
          },
        );
      }),
    );
  }
}

// ── Tile ─────────────────────────────────────────────────────────────────────

class _EntranceSubjectTile extends StatelessWidget {
  const _EntranceSubjectTile({
    required this.subject,
    required this.entranceCount,
    required this.modelCount,
    required this.total,
  });

  final SubjectModel subject;
  final int entranceCount, modelCount, total;

  @override
  Widget build(BuildContext context) {
    final dark = AppHelperFunctions.isDark(context);
    final controller = SubjectsController.instance;

    return Obx(() {
      final step = controller.entranceDownloadStep[subject.id];
      final progress = controller.entranceDownloadProgress[subject.id];
      final isDownloading = step != null;
      final isDownloaded = subject.isEntranceDownloaded;
      final canDownload = total > 0 && !isDownloaded && !isDownloading;
      final noContent = total == 0;

      return Material(
        clipBehavior: Clip.hardEdge,
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusLg),
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSizes.borderRadiusLg),
          onTap: isDownloaded && total > 0
              ? () => Get.toNamed(
                    Routes.entranceExams,
                    arguments: {
                      'subject_id': subject.id,
                      'subject': subject.name,
                    },
                  )
              : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(
                color: isDownloaded
                    ? AppColors.primary.withValues(alpha: 0.6)
                    : AppColors.primary.withValues(alpha: 0.35),
              ),
              borderRadius: BorderRadius.circular(AppSizes.borderRadiusLg),
              color: isDownloading
                  ? AppColors.primary.withValues(alpha: dark ? 0.07 : 0.04)
                  : null,
            ),
            child: Row(
              children: [
                // ── Icon ──────────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary
                        .withValues(alpha: dark ? 0.2 : 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Iconsax.book_square_copy,
                    color: AppColors.primary,
                  ),
                ),

                const SizedBox(width: 12),

                // ── Title + subtitle + progress ───────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        subject.name,
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall!
                            .copyWith(color: AppColors.primary),
                      ),
                      const SizedBox(height: 3),

                      // Subtitle line
                      Text(
                        noContent
                            ? 'Coming soon'
                            : '$entranceCount entrance · $modelCount model exams',
                        style: TextStyle(
                          fontSize: 12,
                          color: dark
                              ? AppColors.grey
                              : AppColors.darkerGrey.withValues(alpha: 0.7),
                        ),
                      ),

                      // Progress bar — only while downloading
                      if (isDownloading && progress != null) ...[
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 4,
                            backgroundColor:
                                AppColors.primary.withValues(alpha: 0.15),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // ── Trailing action ───────────────────────────────────
                _ActionWidget(
                  isDownloading: isDownloading,
                  isDownloaded: isDownloaded,
                  canDownload: canDownload,
                  noContent: noContent,
                  subject: subject,
                  dark: dark,
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}

// ── Action widget (trailing) ──────────────────────────────────────────────────

class _ActionWidget extends StatelessWidget {
  const _ActionWidget({
    required this.isDownloading,
    required this.isDownloaded,
    required this.canDownload,
    required this.noContent,
    required this.subject,
    required this.dark,
  });

  final bool isDownloading, isDownloaded, canDownload, noContent, dark;
  final SubjectModel subject;

  @override
  Widget build(BuildContext context) {
    // Downloading — bar is in the tile, trailing shows nothing
    if (isDownloading) return const SizedBox.shrink();

    // Already downloaded — check badge
    if (isDownloaded) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: dark ? 0.2 : 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_rounded,
                size: 13,
                color: AppColors.primary.withValues(alpha: dark ? 0.9 : 1)),
            const SizedBox(width: 4),
            Text(
              'Ready',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.primary.withValues(alpha: dark ? 0.9 : 1),
              ),
            ),
          ],
        ),
      );
    }

    // No content yet — disabled download button (greyed out)
    if (noContent) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.darkGrey.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.download_rounded,
                size: 13,
                color: AppColors.darkGrey.withValues(alpha: 0.4)),
            const SizedBox(width: 4),
            Text(
              'Download',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.darkGrey.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      );
    }

    // Can download — active button
    return GestureDetector(
      onTap: () => SubjectsController.instance.downloadEntranceExams(subject),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.download_rounded, size: 13, color: Colors.white),
            SizedBox(width: 4),
            Text(
              'Download',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
