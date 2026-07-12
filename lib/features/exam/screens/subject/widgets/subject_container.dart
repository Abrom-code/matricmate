import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matricmate/features/exam/controllers/subjects_controller.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/constants/sizes.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

class SubjectContainer extends StatelessWidget {
  const SubjectContainer({
    super.key,
    required this.title,
    required this.image,
    required this.onTap,
    required this.isDownloaded,
    required this.onPressed,
  });

  final String title, image;
  final VoidCallback onTap, onPressed;
  final bool isDownloaded;

  @override
  Widget build(BuildContext context) {
    final dark = AppHelperFunctions.isDark(context);

    return Obx(() {
      final controller = SubjectsController.instance;
      final isDownloading = controller.downloadingMap[title] ?? false;
      final progress = controller.subjectDownloadProgress[title];

      return GestureDetector(
        onTap: isDownloaded ? onTap : null,
        child: Container(
          padding: const EdgeInsets.all(AppSizes.sm),
          width: 150,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSizes.defaultSpace),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.8)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Header row ────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
              const Divider(),

              // ── Image + download overlay ──────────────────────────
              SizedBox(
                height: 90,
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: dark
                            ? AppColors.darkCard.withValues(alpha: 0.5)
                            : Colors.transparent,
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(AppSizes.defaultSpace),
                          bottomRight: Radius.circular(AppSizes.defaultSpace),
                        ),
                      ),
                      child: ClipRRect(
                        clipBehavior: Clip.hardEdge,
                        child: Image.asset(
                          image,
                          fit: BoxFit.contain,
                          width: double.infinity,
                        ),
                      ),
                    ),

                    if (!isDownloaded)
                      Center(
                        child: GestureDetector(
                          onTap: isDownloading ? null : onPressed,
                          child: SizedBox(
                            width: 44,
                            height: 44,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Background circle
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.darkGrey.withValues(
                                      alpha: 0.72,
                                    ),
                                  ),
                                ),

                                // Circular progress ring (shown while downloading)
                                if (isDownloading)
                                  SizedBox(
                                    width: 40,
                                    height: 40,
                                    child: CircularProgressIndicator(
                                      value: progress,
                                      strokeWidth: 2.5,
                                      color: AppColors.white,
                                      backgroundColor: AppColors.white
                                          .withValues(alpha: 0.2),
                                    ),
                                  ),

                                // Center content: % or icon
                                if (isDownloading && progress != null)
                                  Text(
                                    '${(progress * 100).toInt()}%',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.white,
                                    ),
                                  )
                                else if (!isDownloading)
                                  const Icon(
                                    Icons.cloud_download_rounded,
                                    color: AppColors.white,
                                    size: 22,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}
