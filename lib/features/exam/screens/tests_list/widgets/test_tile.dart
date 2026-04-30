import 'package:flutter/material.dart';
import 'package:matricmate/common/widgets/tiles/tile.dart';
import 'package:matricmate/utils/constants/colors.dart';
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
    return AppTile(
      icon: icon,
      iconBgColor: iconColor,
      subTitle: LinearProgressIndicator(
        borderRadius: BorderRadius.circular(10),
        value: currentStep / maxStep,
        backgroundColor: dark ? AppColors.darkGrey : AppColors.grey,
        color: AppColors.primary,
        minHeight: 8,
      ),
      iconColor: iconColor,
      title: testName,
      onTap: onTap,
    );
  }
}
