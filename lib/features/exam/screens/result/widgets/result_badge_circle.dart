import 'package:flutter/material.dart';
import 'package:matricmate/common/widgets/helpers/badges.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

/// Circular badge shown at the top of the result screen.
class ResultBadgeCircle extends StatelessWidget {
  const ResultBadgeCircle({super.key, required this.ratio});

  final double ratio;

  @override
  Widget build(BuildContext context) {
    final dark = AppHelperFunctions.isDark(context);
    final examBadge = ExamBadgeHelper.getBadge(ratio);
    final percentage = (ratio * 100).round();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 170,
          height: 170,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: dark ? AppColors.darkCard : AppColors.white,
            boxShadow: [
              BoxShadow(
                color: examBadge.color.withValues(alpha: dark ? 0.35 : 0.2),
                blurRadius: 28,
                offset: const Offset(0, 8),
              ),
            ],
            border: Border.all(
              color: examBadge.color.withValues(alpha: 0.3),
              width: 2,
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Circular progress track
              SizedBox(
                width: 148,
                height: 148,
                child: CircularProgressIndicator(
                  value: ratio.clamp(0.0, 1.0),
                  strokeWidth: 8,
                  backgroundColor: dark
                      ? AppColors.darkSurface
                      : const Color(0xFFE2E8F0),
                  valueColor: AlwaysStoppedAnimation<Color>(examBadge.color),
                  strokeCap: StrokeCap.round,
                ),
              ),

              // Center content: icon + percentage
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    examBadge.icon,
                    color: examBadge.color,
                    size: 46,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$percentage%',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                      color: dark ? AppColors.textWhite : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Badge label pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: examBadge.color.withValues(alpha: dark ? 0.22 : 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: examBadge.color.withValues(alpha: 0.4),
              width: 1.2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                examBadge.icon,
                color: examBadge.color,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                examBadge.label,
                style: TextStyle(
                  color: examBadge.color,
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
