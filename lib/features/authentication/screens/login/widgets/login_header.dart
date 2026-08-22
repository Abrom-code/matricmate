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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),

        // Brand logo
        Image.asset(
          AppImages.transparentIcon,
          width: 72,
          height: 72,
          fit: BoxFit.contain,
        ),

        const SizedBox(height: 22),

        // Title
        Text(
          'Welcome Back',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.6,
            color: dark ? AppColors.white : const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 6),

        // Subtitle
        Text(
          'Sign in to access tests, study practice, and exam tracking.',
          style: TextStyle(
            fontSize: 14,
            height: 1.45,
            color: dark ? AppColors.darkGrey : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
