import 'package:flutter/material.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';
import 'package:matricmate/features/exam/controllers/question_controller.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

class PassageLayoutCtrl extends StatelessWidget {
  const PassageLayoutCtrl({super.key, required this.controller});

  final QuestionController controller;

  @override
  Widget build(BuildContext context) {
    final dark = AppHelperFuntions.isDark(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,

      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: Icon(
                Icons.text_decrease,
                size: 20,
                color: dark ? AppColors.grey : Colors.black87,
              ),
              onPressed: controller.decreaseTextScale,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),

            IconButton(
              icon: Icon(
                Icons.text_increase,
                size: 20,
                color: dark ? AppColors.grey : Colors.black87,
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
              '(${controller.formattedTime})',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        Obx(
          () => IconButton(
            icon: Icon(
              !controller.isFullScreenPassage.value
                  ? Icons.keyboard_arrow_down
                  : Icons.keyboard_arrow_up,
              color: dark ? AppColors.grey : Colors.black87,
            ),

            onPressed: controller.togglePassageSize,
          ),
        ),
      ],
    );
  }
}
