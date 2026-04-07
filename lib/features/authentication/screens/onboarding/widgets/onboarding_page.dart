import 'package:flutter/material.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/constants/sizes.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

class OnBoardingPane extends StatelessWidget {
  final String mainText;
  final String mainSubText;
  final String subText;
  final String onboardImage;

  const OnBoardingPane({
    super.key,
    required this.subText,
    required this.mainText,
    required this.mainSubText,
    required this.onboardImage,
  });

  @override
  Widget build(BuildContext context) {
    // Check if current theme is dark
    final isDark = AppHelperFuntions.isDark(context);

    return Padding(
      // Standard padding around the edges makes the layout look professional
      padding: const EdgeInsets.all(AppSizes.defaultSpace),
      child: Column(
        children: [
          const SizedBox(height: AppSizes.spaceBtwSections * 2),
          Image(
            width: AppHelperFuntions.screenWidth() * 0.8,
            height:
                AppHelperFuntions.screenHeight() *
                0.4, // Reduced slightly for breathing room
            image: AssetImage(onboardImage),
          ),
          const SizedBox(height: AppSizes.spaceBtwSections),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                mainText,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5, // Tighter letters look more modern
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(width: AppSizes.sm),

              Text(
                mainSubText,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                  fontSize: 24, // Consistent size rather than delta
                ),
                textAlign: TextAlign.center,
              ),

              /// Circular Button
            ],
          ),
          const SizedBox(height: AppSizes.spaceBtwItems),

          Text(
            subText,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isDark ? Colors.grey[400] : Colors.grey[600],
              height: 1.5, // Improves readability for longer text
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSizes.spaceBtwSections * 2),
        ],
      ),
    );
  }
}
