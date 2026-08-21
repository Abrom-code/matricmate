import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matricmate/features/exam/controllers/subjects_controller.dart';
import 'package:matricmate/features/personalization/controllers/user_controller.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

class SubjectHeader extends StatelessWidget {
  const SubjectHeader({super.key, required this.subjectCount});

  final int subjectCount;

  @override
  Widget build(BuildContext context) {
    final isDark = AppHelperFunctions.isDark(context);
    final userController = UserController.instance;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'My Subjects',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                  color: isDark ? AppColors.textWhite : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Obx(() {
                final stream = userController.user.value.stream;
                final streamLabel = stream.isNotEmpty
                    ? '${stream[0].toUpperCase()}${stream.substring(1)} Stream'
                    : 'Grade 12';
                return Text(
                  '$streamLabel • $subjectCount subjects',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDark ? AppColors.darkGrey : AppColors.textSecondary,
                  ),
                );
              }),
            ],
          ),

          // Download all / Stream indicator
          Obx(() {
            final isDownloadingAny = SubjectsController.instance.downloadingMap.values
                .any((isDown) => isDown);

            if (isDownloadingAny) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: isDark ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 10,
                      height: 10,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Downloading...',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              );
            }

            return const SizedBox.shrink();
          }),
        ],
      ),
    );
  }
}
