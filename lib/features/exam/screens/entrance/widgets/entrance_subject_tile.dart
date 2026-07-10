import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:matricmate/features/exam/controllers/subjects_controller.dart';
import 'package:matricmate/features/exam/models/subject_model.dart';
import 'package:matricmate/features/exam/screens/entrance/widgets/entrance_action_widget.dart';
import 'package:matricmate/routes/app_routes.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/constants/sizes.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

class EntranceSubjectTile extends StatelessWidget {
  const EntranceSubjectTile({
    super.key,
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
                    color: AppColors.primary.withValues(
                      alpha: dark ? 0.2 : 0.1,
                    ),
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
                        style:
                            Theme.of(context).textTheme.titleSmall!.copyWith(
                                  color: AppColors.primary,
                                ),
                      ),
                      const SizedBox(height: 3),
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
                            backgroundColor: AppColors.primary.withValues(
                              alpha: 0.15,
                            ),
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
                EntranceActionWidget(
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
