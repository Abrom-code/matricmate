import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matricmate/common/widgets/appbar/appbar.dart';
import 'package:matricmate/features/exam/controllers/result_controller.dart';
import 'package:matricmate/features/exam/screens/result/widgets/result_action_buttons.dart';
import 'package:matricmate/features/exam/screens/result/widgets/result_badge_circle.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

class ResultScreen extends GetView<ResultController> {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = AppHelperFunctions.isDark(context);
    final result = controller.result;
    final totalQns = result.testQuestions.length;
    final correctQns = result.correctAnswers;
    final answeredCount = result.selectedAnswers.length;
    final incorrectQns = answeredCount > correctQns ? answeredCount - correctQns : 0;
    final skippedQns = totalQns > answeredCount ? totalQns - answeredCount : 0;

    final ratio = totalQns == 0 ? 0.0 : correctQns / totalQns;

    return Scaffold(
      backgroundColor: dark ? AppColors.dark : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: Appbar.toolbarHeight(context),
        leading: Padding(
          padding: const EdgeInsets.only(left: 4),
          child: IconButton(
            onPressed: Get.back,
            tooltip: 'Back',
            icon: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 16,
                  color: AppColors.white,
                ),
              ),
            ),
          ),
        ),
        title: const Text(
          'Test Result',
          style: TextStyle(
            color: AppColors.white,
            fontSize: 18.5,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Builder(
          builder: (context) {
            final isLandscape =
                MediaQuery.orientationOf(context) == Orientation.landscape;

            final badge = ResultBadgeCircle(ratio: ratio);

            final metricsCard = Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: dark ? AppColors.darkCard : AppColors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: dark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: dark ? 0.25 : 0.04),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Correct
                  Expanded(
                    child: _buildMetricTile(
                      label: 'Correct',
                      value: '$correctQns',
                      color: const Color(0xFF10B981),
                      icon: Icons.check_circle_rounded,
                      dark: dark,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: dark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
                  ),

                  // Incorrect
                  Expanded(
                    child: _buildMetricTile(
                      label: 'Wrong',
                      value: '$incorrectQns',
                      color: const Color(0xFFEF4444),
                      icon: Icons.cancel_rounded,
                      dark: dark,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: dark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
                  ),

                  // Skipped
                  Expanded(
                    child: _buildMetricTile(
                      label: 'Skipped',
                      value: '$skippedQns',
                      color: const Color(0xFFF59E0B),
                      icon: Icons.skip_next_rounded,
                      dark: dark,
                    ),
                  ),
                ],
              ),
            );

            final content = Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                metricsCard,
                const SizedBox(height: 24),
                ResultActionButtons(result: result),
              ],
            );

            if (isLandscape) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(child: Center(child: badge)),
                  const SizedBox(width: 24),
                  Expanded(child: content),
                ],
              );
            }

            return Column(
              children: [
                const SizedBox(height: 8),
                badge,
                const SizedBox(height: 28),
                content,
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
    required bool dark,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: dark ? AppColors.darkGrey : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
