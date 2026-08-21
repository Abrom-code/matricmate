import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matricmate/features/exam/controllers/premium_controller.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';
import 'package:matricmate/utils/validators/validators.dart';

class LinkInputField extends StatelessWidget {
  const LinkInputField({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<PremiumController>();
    final isDark = AppHelperFunctions.isDark(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'TRANSACTION LINK OR REF (OPTIONAL)',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: isDark ? AppColors.darkGrey : AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller.urlFiledController,
          onTapOutside: (_) => FocusScope.of(context).unfocus(),
          style: TextStyle(
            fontSize: 13,
            color: isDark ? AppColors.textWhite : AppColors.textPrimary,
          ),
          validator: (value) => (value == null || value.trim().isEmpty)
              ? null
              : AppValidator.isValidUrl(value),
          decoration: InputDecoration(
            hintText: 'https://telebirr.et/receipt/... or SMS text',
            hintStyle: TextStyle(
              fontSize: 12,
              color: isDark ? AppColors.darkGrey : AppColors.textSecondary,
            ),
            prefixIcon: Container(
              margin: const EdgeInsets.all(10),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: isDark ? 0.2 : 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.link_rounded,
                size: 16,
                color: AppColors.primary,
              ),
            ),
            suffixIcon: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () async {
                await controller.pasteFromClipboard();
              },
              child: Container(
                margin: const EdgeInsets.all(8),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : AppColors.grey.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.content_paste_rounded,
                      size: 14,
                      color: isDark ? AppColors.textWhite : AppColors.textPrimary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Paste',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.textWhite : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            filled: true,
            fillColor: isDark ? AppColors.darkSurface : AppColors.lightCard,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: isDark ? AppColors.darkBorder : AppColors.borderPrimary,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: isDark ? AppColors.darkBorder : AppColors.borderPrimary,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
