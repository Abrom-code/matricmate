import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matricmate/features/exam/controllers/question_controller.dart';
import 'package:matricmate/utils/constants/colors.dart';

/// Shown in the appbar when the current question has a passage.
/// Displays the question counter and optional timer — text-scale
/// controls have moved to the passage header itself.
class PassageLayoutCtrl extends StatelessWidget {
  const PassageLayoutCtrl({super.key, required this.controller});

  final QuestionController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() => Text(
      '${controller.currentIndex.value + 1} of ${controller.testQuestions.length}'
      '${controller.isTimed ? ' (${controller.formattedTime(controller.remainingSeconds.value)})' : ''}',
      style: Theme.of(context).textTheme.titleMedium!.copyWith(
        color: AppColors.primary,
      ),
    ));
  }
}
