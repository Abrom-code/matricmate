import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matricmate/features/exam/controllers/question_controller.dart';
import 'package:matricmate/utils/constants/colors.dart';

/// Shown in the appbar when the current question has a passage.
/// Tapping it toggles the passage panel (show / hide).
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
                style: Theme.of(context).textTheme.titleMedium!.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(width: 4),
            // eye icon shows current state
            Icon(
              hidden
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              color: AppColors.primary.withValues(alpha: 0.7),
              size: 16,
            ),
            // timer if timed
            if (controller.isTimed) ...[
              const SizedBox(width: 4),
              Text(
                '(${controller.formattedTime(controller.remainingSeconds.value)})',
                style: Theme.of(context).textTheme.labelMedium!.copyWith(
                  color: controller.remainingSeconds.value < 300
                      ? Colors.amber
                      : AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      );
    });
  }
}
