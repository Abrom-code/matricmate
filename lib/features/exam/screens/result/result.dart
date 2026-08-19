import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matricmate/common/widgets/appbar/appbar.dart';
import 'package:matricmate/features/exam/controllers/result_controller.dart';
import 'package:matricmate/features/exam/screens/result/widgets/result_action_buttons.dart';
import 'package:matricmate/features/exam/screens/result/widgets/result_badge_circle.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/constants/sizes.dart';

class ResultScreen extends GetView<ResultController> {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final result = controller.result;
    final ratio = result.testQuestions.isEmpty
        ? 0.0
        : result.correctAnswers / result.testQuestions.length;

    return Scaffold(
      appBar: Appbar(
        title: Text(
          'Your Result',
          style: Theme.of(
            context,
          ).textTheme.headlineMedium!.apply(color: AppColors.white),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.defaultSpace),
          child: Builder(
            builder: (context) {
              final isLandscape =
                  MediaQuery.orientationOf(context) == Orientation.landscape;

              final badge = ResultBadgeCircle(ratio: ratio);
              final scoreText = Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'TEST RESULT',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSizes.spaceBtwItems / 2),
                  Text(
                    '${result.correctAnswers}/${result.testQuestions.length}',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 44,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: AppSizes.spaceBtwSections),
                  ResultActionButtons(result: result),
                ],
              );

              if (isLandscape) {
                // Side-by-side: badge left, score + buttons right
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(child: Center(child: badge)),
                    const SizedBox(width: AppSizes.spaceBtwSections),
                    Expanded(child: scoreText),
                  ],
                );
              }

              // Portrait: stacked
              return Column(
                children: [
                  badge,
                  const SizedBox(height: AppSizes.spaceBtwSections),
                  scoreText,
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
