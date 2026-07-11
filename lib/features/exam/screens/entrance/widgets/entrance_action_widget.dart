import 'package:flutter/material.dart';
import 'package:matricmate/features/exam/controllers/subjects_controller.dart';
import 'package:matricmate/features/exam/models/subject_model.dart';
import 'package:matricmate/utils/constants/colors.dart';

class EntranceActionWidget extends StatelessWidget {
  const EntranceActionWidget({
    super.key,
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
    // Downloading — progress bar is in the tile, trailing shows nothing
    if (isDownloading) return const SizedBox.shrink();

    // Already downloaded — icon only
    if (isDownloaded) {
      return Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.primary.withValues(alpha: dark ? 0.2 : 0.12),
        ),
        child: Icon(
          Icons.check_rounded,
          size: 16,
          color: AppColors.primary.withValues(alpha: dark ? 0.9 : 1),
        ),
      );
    }

    // No content yet — disabled download button (greyed out)
    if (noContent) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: AppColors.darkGrey.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.download_rounded,
              size: 13,
              color: AppColors.darkGrey.withValues(alpha: 0.4),
            ),
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
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
