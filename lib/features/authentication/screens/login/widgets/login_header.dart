import 'package:flutter/material.dart';
import 'package:matricmate/utils/constants/app_images.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

class AppDetail extends StatelessWidget {
  const AppDetail({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = AppHelperFunctions.isDark(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 8),

        // Brand Logo centered on the top of the input fields
        Center(
          child: Container(
            width: 64,
            height: 64,
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: dark ? AppColors.darkCard : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: dark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: dark ? 0.25 : 0.10),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: dark ? 0.2 : 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Image.asset(
              AppImages.transparentIcon,
              fit: BoxFit.contain,
            ),
          ),
        ),

        const SizedBox(height: 18),

        // Centered Title
        Center(
          child: Text(
            'Login',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.6,
              color: dark ? AppColors.white : const Color(0xFF0F172A),
            ),
          ),
        ),

        const SizedBox(height: 6),

        // Centered Subtitle
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Login to access tests, study practice, and exam tracking.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5,
                height: 1.4,
                color: dark ? AppColors.darkGrey : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
