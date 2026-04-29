import 'package:flutter/material.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/constants/sizes.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

class TestTile extends StatelessWidget {
  const TestTile({
    super.key,
    required this.testName,
    this.icon = Icons.quiz,
    required this.onTap,
    this.hasSubTitle = true,
    required this.currentStep,
    required this.maxStep,
    this.iconColor = AppColors.primary,
  });
  final String testName;
  final IconData icon;
  final VoidCallback onTap;
  final bool hasSubTitle;
  final int currentStep, maxStep;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    final dark = AppHelperFuntions.isDark(context);
    return Material(
      clipBehavior: Clip.hardEdge,
      borderRadius: BorderRadius.circular(AppSizes.borderRadiusLg),
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(AppSizes.borderRadiusLg),
        ),
        child: ListTile(
          minVerticalPadding: 10,
          leading: Icon(icon, color: iconColor),
          title: Text(
            testName.toUpperCase(),
            style: Theme.of(
              context,
            ).textTheme.titleSmall!.apply(color: AppColors.primary),
          ),
          subtitle: LinearProgressIndicator(
            borderRadius: BorderRadius.circular(10),
            value: currentStep / maxStep,
            backgroundColor: dark ? AppColors.darkGrey : AppColors.grey,
            color: AppColors.primary,
            minHeight: 8,
          ),
          visualDensity: VisualDensity(vertical: 2),

          onTap: onTap,
        ),
      ),
    );
  }
}
