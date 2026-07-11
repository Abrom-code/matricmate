import 'package:flutter/material.dart';
import 'package:matricmate/features/exam/controllers/question_controller.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/constants/sizes.dart';

/// Single numbered tile inside the question navigator grid.
class QuestionNavigatorTile extends StatelessWidget {
  const QuestionNavigatorTile({
    super.key,
    required this.index,
    required this.controller,
    required this.dark,
  });

  final int index;
  final QuestionController controller;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final q = controller.testQuestions[index];
    final isCurrent = controller.currentIndex.value == index;
    final isSkipped = controller.isSkipped(q.id);
    final isDone = controller.isExamMode
        ? controller.selectedAnswers.containsKey(q.id)
        : controller.isAnswerChecked(q.id);

    final Color bg;
    if (isDone) {
      bg = AppColors.success;
    } else if (isSkipped) {
      bg = Colors.amber;
    } else {
      bg = dark ? AppColors.darkSurface : AppColors.grey;
    }

    return GestureDetector(
      onTap: () {
        controller.jumpToQuestion(index);
        Navigator.pop(context);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
          border: isCurrent
              ? Border.all(color: AppColors.primary, width: 2.5)
              : null,
          boxShadow: isCurrent
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.4),
                    blurRadius: 6,
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            '${q.questionOrder ?? index + 1}',
            style: TextStyle(
              color: isDone || isSkipped
                  ? AppColors.white
                  : dark
                      ? AppColors.white.withValues(alpha: 0.8)
                      : AppColors.darkerGrey,
              fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Legend dot ────────────────────────────────────────────────────────────────

class NavigatorLegendDot extends StatelessWidget {
  const NavigatorLegendDot({
    super.key,
    required this.color,
    required this.label,
  });

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 3),
        Text(
          label,
          style: Theme.of(context)
              .textTheme
              .labelSmall!
              .copyWith(color: AppColors.darkGrey),
        ),
      ],
    );
  }
}
