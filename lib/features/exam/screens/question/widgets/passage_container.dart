import 'package:flutter/material.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';
import 'package:matricmate/features/exam/controllers/question_controller.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

class PassageContainer extends StatelessWidget {
  const PassageContainer({super.key, required this.controller});

  final QuestionController controller;

  @override
  Widget build(BuildContext context) {
    final dark = AppHelperFuntions.isDark(context);

    return Obx(() {
      final block = controller.blocks[controller.currentBlockIndex.value];

      return AnimatedContainer(
        duration: const Duration(milliseconds: 300),

        constraints: BoxConstraints(
          maxHeight: controller.isFullScreenPassage.value
              ? MediaQuery.of(context).size.height * 0.8
              : MediaQuery.of(context).size.height * 0.35,
        ),

        child: Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: dark
                    ? Colors.white.withValues(alpha: 0.15)
                    : Colors.black.withValues(alpha: 0.08),
                blurRadius: 1,
                offset: const Offset(0, 1),
              ),
            ],
            border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
          ),

          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: Column(
                children: [
                  const SizedBox(height: 10),

                  if (block.passage?.title != null)
                    Text(
                      block.passage?.title ?? "",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 17 * controller.textScale.value,
                      ),
                    ),
                  if (block.passage?.title != null) const SizedBox(height: 10),

                  Center(
                    child: SelectableText(
                      block.passage?.content ?? "Loading...",
                      textAlign: TextAlign.justify,
                      style: TextStyle(
                        fontSize: 15 * controller.textScale.value,
                        height: 1.7,
                        color: dark ? AppColors.grey : Colors.black87,
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }
}
