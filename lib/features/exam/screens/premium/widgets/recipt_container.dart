import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

class ReciptContainer extends StatelessWidget {
  final XFile? file;

  const ReciptContainer({super.key, this.file});

  @override
  Widget build(BuildContext context) {
    final isDark = AppHelperFunctions.isDark(context);

    return Container(
      width: double.infinity,
      height: file == null ? null : 300,
      padding: file == null
          ? const EdgeInsets.symmetric(vertical: 28)
          : const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.4),
          width: 1.5,
        ),
        color: isDark ? AppColors.dark : AppColors.lightContainer,
      ),
      child: file == null
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.cloud_upload_outlined,
                    color: AppColors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Upload Receipt Screenshot',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 6),
                const Text(
                  'PNG, JPG OR PDF UP TO 5MB',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.darkGrey,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            )
          // WHEN IMAGE IS SELECTED
          : ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.file(
                File(file!.path),
                fit: BoxFit.contain,
                height: 150,
              ),
            ),
    );
  }
}
