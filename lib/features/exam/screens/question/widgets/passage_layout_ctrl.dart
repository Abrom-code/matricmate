import 'package:flutter/material.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';
import 'package:matricmate/features/exam/controllers/question_controller.dart';
import 'package:matricmate/utils/constants/colors.dart';

class PassageLayoutCtrl extends StatelessWidget {
  const PassageLayoutCtrl({super.key, required this.controller});

  final QuestionController controller;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,

      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: Icon(
                Icons.text_decrease,
                size: 20,
                color: AppColors.primary,
              ),
              onPressed: controller.decreaseTextScale,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),

            IconButton(
              icon: Icon(
                Icons.text_increase,
                size: 20,
                color: AppColors.primary,
              ),
              onPressed: controller.increaseTextScale,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
        if (controller.isTimed)
          Obx(
            () => Text(
              '(${controller.formattedTime(controller.remainingSeconds.value)})',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium!.copyWith(color: AppColors.primary),
            ),
          ),
      ],
    );
  }
}
