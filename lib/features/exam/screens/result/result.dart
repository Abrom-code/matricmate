import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matricmate/common/widgets/appbar/appbar.dart';
import 'package:matricmate/features/exam/models/result_model.dart';
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
          style: Theme.of(context)
              .textTheme
              .headlineMedium!
              .apply(color: AppColors.white),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.defaultSpace),
          child: Column(
            children: [
              ResultBadgeCircle(ratio: ratio),
              const SizedBox(height: AppSizes.spaceBtwSections),

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
          ),
        ),
      ),
    );
  }
}

class ResultController extends GetxController {
  static ResultController get instance => Get.find();

  late ResultModel result;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args == null || args is! Map || args['result'] is! ResultModel) {
      Get.back();
      return;
    }
    result = args['result'] as ResultModel;
  }
}
