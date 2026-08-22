import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matricmate/features/exam/controllers/subjects_controller.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

class SubjectContainer extends StatelessWidget {
  const SubjectContainer({
    super.key,
    required this.title,
    required this.image,
    required this.onTap,
    required this.isDownloaded,
    required this.onPressed,
    this.onDelete,
  });

  final String title, image;
  final VoidCallback onTap, onPressed;
  final VoidCallback? onDelete;
  final bool isDownloaded;

  @override
  Widget build(BuildContext context) {
    final dark = AppHelperFunctions.isDark(context);

    return Obx(() {
      final controller = SubjectsController.instance;
      final isDownloading = controller.downloadingMap[title] ?? false;
      final progress = controller.subjectDownloadProgress[title];

      final cardBg = dark ? AppColors.darkCard : AppColors.white;
      final borderColor = isDownloaded
          ? (dark ? AppColors.darkBorder : AppColors.borderPrimary)
          : (dark ? AppColors.darkBorder : AppColors.borderPrimary);

      return Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDownloading
                ? AppColors.primary
                : borderColor,
            width: isDownloading ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: dark ? 0.25 : 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: isDownloaded
                ? onTap
                : (isDownloading ? null : onPressed),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Image Frame with Download Action/Status ────────
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: dark
                            ? AppColors.darkSurface
                            : AppColors.primary.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Subject illustration
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Image.asset(
                              image,
                              fit: BoxFit.contain,
                              width: double.infinity,
                            ),
                          ),

                          // Download Status Chip / Overlay
                          if (!isDownloaded)
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.35),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Center(
                                  child: GestureDetector(
                                    onTap: isDownloading ? null : onPressed,
                                    child: Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: AppColors.primary,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppColors.primary.withValues(alpha: 0.4),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: isDownloading
                                          ? Stack(
                                              alignment: Alignment.center,
                                              children: [
                                                CircularProgressIndicator(
                                                  value: progress,
                                                  strokeWidth: 2.5,
                                                  color: AppColors.white,
                                                  backgroundColor: AppColors.white.withValues(alpha: 0.2),
                                                ),
                                                if (progress != null)
                                                  Text(
                                                    '${(progress * 100).toInt()}%',
                                                    style: const TextStyle(
                                                      fontSize: 9,
                                                      fontWeight: FontWeight.w800,
                                                      color: AppColors.white,
                                                    ),
                                                  ),
                                              ],
                                            )
                                          : const Icon(
                                              Icons.cloud_download_rounded,
                                              color: AppColors.white,
                                              size: 22,
                                            ),
                                    ),
                                  ),
                                ),
                              ),
                            )
                          else ...[
                            // Ready status checkmark (top-left)
                            Positioned(
                              top: 6,
                              left: 6,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: AppColors.success.withValues(alpha: dark ? 0.25 : 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check_rounded,
                                  size: 11,
                                  color: AppColors.success,
                                ),
                              ),
                            ),

                            // Delete / remove from device icon button (top-right)
                            if (onDelete != null)
                              Positioned(
                                top: 6,
                                right: 6,
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: onDelete,
                                    customBorder: const CircleBorder(),
                                    child: Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        color: dark
                                            ? const Color(0xFFEF4444)
                                                .withValues(alpha: 0.18)
                                            : const Color(0xFFFEE2E2),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: const Color(0xFFEF4444)
                                              .withValues(
                                            alpha: dark ? 0.40 : 0.30,
                                          ),
                                          width: 1.0,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFFEF4444)
                                                .withValues(
                                              alpha: dark ? 0.25 : 0.12,
                                            ),
                                            blurRadius: 6,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: const Center(
                                        child: Icon(
                                          Icons.delete_outline_rounded,
                                          size: 15,
                                          color: Color(0xFFEF4444),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // ── Subject Name & Status ──────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                            color: dark ? AppColors.textWhite : AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 11,
                        color: dark ? AppColors.darkGrey : AppColors.grey,
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isDownloaded
                        ? 'Ready to practice'
                        : (isDownloading ? 'Downloading...' : 'Tap to download'),
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                      color: isDownloaded
                          ? AppColors.success
                          : (isDownloading ? AppColors.primary : (dark ? AppColors.darkGrey : AppColors.textSecondary)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }
}
