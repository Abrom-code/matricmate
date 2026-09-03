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

      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Passage toggle pill ─────────────────────────────────────
          GestureDetector(
            onTap: controller.togglePassage,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 5,
              ),
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.white.withValues(alpha: 0.15),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.article_outlined,
                    size: 14,
                    color: AppColors.white.withValues(alpha: 0.8),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Passage',
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.1,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    hidden
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: AppColors.white.withValues(alpha: 0.7),
                    size: 15,
                  ),
                ],
              ),
            ),
          ),

          // ── Timer badge ────────────────────────────────────────────
          if (controller.isTimed) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 7,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: controller.remainingSeconds.value < 300
                    ? Colors.red.withValues(alpha: 0.3)
                    : AppColors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: controller.remainingSeconds.value < 300
                      ? Colors.redAccent.withValues(alpha: 0.5)
                      : AppColors.white.withValues(alpha: 0.15),
                  width: 0.8,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.timer_outlined,
                    size: 12,
                    color: controller.remainingSeconds.value < 300
                        ? Colors.amberAccent
                        : const Color(0xFFD1FAE5),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    controller.formattedTime(
                      controller.remainingSeconds.value,
                    ),
                    style: TextStyle(
                      color: controller.remainingSeconds.value < 300
                          ? Colors.amberAccent
                          : const Color(0xFFD1FAE5),
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      );
    });
  }
}

