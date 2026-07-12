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
    this.correctAnswers = 0,
    this.isInProgress = false,
  });

  final String testName;
  final IconData icon;
  final VoidCallback onTap;
  final bool hasSubTitle;
  final int currentStep, maxStep;
  final Color iconColor;

  /// Number of correct answers from the last completed attempt.
  final int correctAnswers;

  /// True when the user left mid-test without submitting.
  final bool isInProgress;

  @override
  Widget build(BuildContext context) {
    final dark = AppHelperFunctions.isDark(context);
    final hasAttempt = maxStep > 0 && currentStep > 0;

    return AppTile(
      icon: icon,
      iconBgColor: iconColor,
      subTitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Score label + resume badge row
          if (hasAttempt) ...[
            Row(
              children: [
                // Correct / total score
                if (!isInProgress)
                  Text(
                    '$correctAnswers/$maxStep correct',
                    style: TextStyle(
                      fontSize: 11,
                      color: dark
                          ? AppColors.white.withValues(alpha: 0.5)
                          : AppColors.darkerGrey.withValues(alpha: 0.6),
                    ),
                  ),
                // Resume badge
                if (isInProgress) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.primary, width: 0.8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.play_arrow_rounded,
                          size: 11,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          'Resume  •  $currentStep/$maxStep answered',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 4),
          ],
          // Progress bar
          LinearProgressIndicator(
            borderRadius: BorderRadius.circular(10),
            value: maxStep > 0 ? (currentStep / maxStep).clamp(0.0, 1.0) : 0.0,
            backgroundColor: dark ? AppColors.darkGrey : AppColors.grey,
            color: isInProgress ? Colors.orange : AppColors.primary,
            minHeight: 8,
          ),
        ],
      ),
      iconColor: iconColor,
      title: testName,
      onTap: onTap,
    );
  }
}
