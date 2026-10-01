import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

class ReceiptContainer extends StatelessWidget {
  final XFile? file;
  final bool hasError;

  const ReceiptContainer({
    super.key,
    this.file,
    this.hasError = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = AppHelperFunctions.isDark(context);
    final showError = hasError && file == null;

    final borderColor = file != null
        ? AppColors.primary
        : (showError
            ? AppColors.error
            : (isDark ? AppColors.darkBorder : AppColors.borderPrimary));

    final borderWidth = (file != null || showError) ? 2.0 : 1.5;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          height: file == null ? 160 : 260,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: showError
                ? (isDark
                    ? AppColors.error.withValues(alpha: 0.08)
                    : const Color(0xFFFFF5F5))
                : (isDark ? AppColors.darkSurface : AppColors.lightCard),
            border: Border.all(
              color: borderColor,
              width: borderWidth,
            ),
          ),
          child: file == null
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: showError
                              ? [
                                  AppColors.error,
                                  AppColors.error.withValues(alpha: 0.8),
                                ]
                              : [
                                  AppColors.primary,
                                  AppColors.primary.withValues(alpha: 0.8),
                                ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: (showError
                                    ? AppColors.error
                                    : AppColors.primary)
                                .withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        showError
                            ? Icons.error_outline_rounded
                            : Icons.add_photo_alternate_rounded,
                        color: AppColors.white,
                        size: 26,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Upload Receipt Screenshot',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: showError
                            ? AppColors.error
                            : (isDark
                                ? AppColors.textWhite
                                : AppColors.textPrimary),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      showError
                          ? 'Receipt screenshot is required'
                          : 'Tap to choose PNG or JPG from gallery',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: showError
                            ? AppColors.error.withValues(alpha: 0.85)
                            : (isDark
                                ? AppColors.darkGrey
                                : AppColors.textSecondary),
                      ),
                    ),
                  ],
                )
              : Stack(
                  children: [
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.file(
                          File(file!.path),
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    // Floating Change Badge
                    Positioned(
                      bottom: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.black.withValues(alpha: 0.75),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.white.withValues(alpha: 0.2),
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.edit_rounded,
                              size: 13,
                              color: AppColors.white,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Change',
                              style: TextStyle(
                                color: AppColors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
        ),
        if (showError) ...[
          const SizedBox(height: 8),
          const Row(
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 14,
                color: AppColors.error,
              ),
              SizedBox(width: 5),
              Text(
                'Please upload receipt screenshot',
                style: TextStyle(
                  color: AppColors.error,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
