import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:matricmate/features/exam/models/result_model.dart';
import 'package:matricmate/navigation_menu.dart';
import 'package:matricmate/routes/app_routes.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/constants/sizes.dart';

/// Review Answers + Back + Home buttons shown at the bottom of the result screen.
class ResultActionButtons extends StatelessWidget {
  const ResultActionButtons({super.key, required this.result});

  final ResultModel result;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Review Answers — primary filled
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => Get.toNamed(Routes.review, arguments: result),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.borderRadiusLg),
              ),
            ),
            icon: const Icon(Iconsax.search_status_1_copy, size: 20),
            label: const Text(
              'Review Answers',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(height: AppSizes.spaceBtwItems),

        // Back + Home — side by side
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => Get.back(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppSizes.borderRadiusLg),
                  ),
                ),
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16),
                label: const Text(
                  'Back',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ),
            ),
            const SizedBox(width: AppSizes.spaceBtwItems),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  NavigationController.instance.selectedIdx.value = 0;
                  Get.offAllNamed(Routes.navigationMenu);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                  foregroundColor: AppColors.primary,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppSizes.borderRadiusLg),
                    side: BorderSide(
                      color: AppColors.primary.withValues(alpha: 0.4),
                    ),
                  ),
                ),
                icon: const Icon(Icons.home_outlined, size: 18),
                label: const Text(
                  'Home',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
