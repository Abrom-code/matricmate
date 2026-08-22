import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matricmate/features/exam/controllers/question_controller.dart';
import 'package:matricmate/utils/constants/colors.dart';

/// Appbar action toggle for questions with an associated passage.
class PassageLayoutCtrl extends StatelessWidget {
  const PassageLayoutCtrl({super.key, required this.controller});

  final QuestionController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final hidden = controller.isPassageHidden.value;
      final block = controller.blocks.isNotEmpty
          ? controller.blocks[controller.currentBlockIndex.value]
          : null;
      final title = (block?.passage?.title?.trim().isNotEmpty == true)
          ? block!.passage!.title!
          : 'Reading Passage';

      return GestureDetector(
        onTap: controller.togglePassage,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // passage title (truncated)
            Flexible(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 6),
            // eye icon shows current state
            Icon(
              hidden
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              color: AppColors.white.withValues(alpha: 0.85),
              size: 17,
            ),
            // timer if timed
            if (controller.isTimed) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: controller.remainingSeconds.value < 300
                      ? Colors.red.withValues(alpha: 0.3)
                      : AppColors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  controller.formattedTime(controller.remainingSeconds.value),
                  style: TextStyle(
                    color: controller.remainingSeconds.value < 300
                        ? Colors.amberAccent
                        : const Color(0xFFD1FAE5),
                    fontWeight: FontWeight.w700,
                    fontSize: 11.5,
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    });
  }
}
