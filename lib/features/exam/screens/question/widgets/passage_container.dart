import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matricmate/features/exam/controllers/question_controller.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

class PassageContainer extends StatelessWidget {
  const PassageContainer({super.key, required this.controller});

  final QuestionController controller;

  @override
  Widget build(BuildContext context) {
    final dark = AppHelperFunctions.isDark(context);

    return Obx(() {
      final block = controller.blocks[controller.currentBlockIndex.value];

      return AnimatedContainer(
        duration: const Duration(milliseconds: 300),

        constraints: BoxConstraints(
          maxHeight: controller.isFullScreenPassage.value
              ? MediaQuery.of(context).size.height * 0.8
              : MediaQuery.of(context).size.height * 0.35,
        ),
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

          gradient: !controller.isFullScreenPassage.value
              ? LinearGradient(
                  begin: Alignment.center,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    dark ? AppColors.black : AppColors.darkerGrey,
                  ],
                )
              : null,

          border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Column(
                  children: [
                    const SizedBox(height: 10),

                    if (block.passage?.title != null)
                      Text(
                        block.passage?.title ?? '',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 17 * controller.textScale.value,
                        ),
                      ),
                    if (block.passage?.title != null)
                      const SizedBox(height: 10),

                    Center(
                      child: SelectableText(
                        block.passage?.content ?? 'Loading...',
                        textAlign: TextAlign.start,
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
            Positioned(
              bottom: 0,

              right: 20,
              child: CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primary.withValues(alpha: 0.8),
                child: Center(
                  child: IconButton(
                    icon: Icon(
                      !controller.isFullScreenPassage.value
                          ? Icons.keyboard_arrow_down
                          : Icons.keyboard_arrow_up,
                      color: AppColors.grey,
                      size: 25,
                    ),

                    onPressed: controller.togglePassageSize,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}
