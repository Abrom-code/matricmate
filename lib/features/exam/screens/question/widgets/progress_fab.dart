import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matricmate/features/exam/controllers/question_controller.dart';
import 'package:matricmate/utils/constants/colors.dart';

/// FAB that shows a progress ring around a grid icon.
/// [onPressed] opens the question navigator sheet.
class ProgressFab extends StatelessWidget {
  const ProgressFab({
    super.key,
    required this.controller,
    required this.onPressed,
  });

  final QuestionController controller;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final total = controller.testQuestions.length;
      final done = controller.isExamMode
          ? controller.selectedAnswers.length
          : controller.isChecked.values.where((v) => v).length;
      final progress = total == 0 ? 0.0 : done / total;

      return GestureDetector(
        onTap: onPressed,
        child: SizedBox(
          width: 56,
          height: 56,
          child: CustomPaint(
            painter: ProgressRingPainter(
              progress: progress,
              ringColor: AppColors.primary,
              trackColor: AppColors.primary.withValues(alpha: 0.18),
            ),
            child: Container(
              margin: const EdgeInsets.all(5),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.grid_view_rounded,
                color: AppColors.white,
                size: 22,
              ),
            ),
          ),
        ),
      );
    });
  }
}

// ── Ring painter ──────────────────────────────────────────────────────────────

class ProgressRingPainter extends CustomPainter {
  const ProgressRingPainter({
    required this.progress,
    required this.ringColor,
    required this.trackColor,
  });

  final double progress;
  final Color ringColor;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 3.5;
    final rect = Rect.fromLTWH(
      strokeWidth / 2,
      strokeWidth / 2,
      size.width - strokeWidth,
      size.height - strokeWidth,
    );

    canvas.drawArc(
      rect, -1.5708, 6.2832, false,
      Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );

    if (progress > 0) {
      canvas.drawArc(
        rect, -1.5708, 6.2832 * progress, false,
        Paint()
          ..color = ringColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(ProgressRingPainter old) => old.progress != progress;
}
