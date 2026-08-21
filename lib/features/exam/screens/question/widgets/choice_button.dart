import 'package:flutter/material.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';
import 'package:matricmate/utils/helpers/rich_text_parser.dart';

class ChoiceButton extends StatelessWidget {
  const ChoiceButton({
    super.key,
    required this.optionTxt,
    required this.index,
    required this.questionId,
    required this.correctIndex,
    this.onTap,
    required this.isChecked,
    required this.selectedIndex,
  });

  final String optionTxt;
  final int index;
  final int questionId;
  final int correctIndex;
  final VoidCallback? onTap;
  final bool isChecked;
  final int selectedIndex;

  @override
  Widget build(BuildContext context) {
    final dark = AppHelperFunctions.isDark(context);
    final isSelected = selectedIndex == index;
    final isCorrect = index == correctIndex;

    Color bgColor;
    Color borderColor;
    Color badgeColor;
    Color badgeTextColor;

    if (isChecked) {
      if (isCorrect) {
        bgColor = const Color(0xFF10B981).withValues(alpha: dark ? 0.20 : 0.10);
        borderColor = const Color(0xFF10B981);
        badgeColor = const Color(0xFF10B981);
        badgeTextColor = Colors.white;
      } else if (isSelected) {
        bgColor = const Color(0xFFEF4444).withValues(alpha: dark ? 0.20 : 0.10);
        borderColor = const Color(0xFFEF4444);
        badgeColor = const Color(0xFFEF4444);
        badgeTextColor = Colors.white;
      } else {
        bgColor = dark ? AppColors.darkCard : const Color(0xFFF8FAFC);
        borderColor = dark ? AppColors.darkBorder : const Color(0xFFE2E8F0);
        badgeColor = dark ? AppColors.darkSurface : const Color(0xFFE2E8F0);
        badgeTextColor = dark ? AppColors.darkGrey : AppColors.textSecondary;
      }
    } else {
      if (isSelected) {
        bgColor = AppColors.primary.withValues(alpha: dark ? 0.25 : 0.08);
        borderColor = AppColors.primary;
        badgeColor = AppColors.primary;
        badgeTextColor = Colors.white;
      } else {
        bgColor = dark ? AppColors.darkCard : const Color(0xFFF8FAFC);
        borderColor = dark ? AppColors.darkBorder : const Color(0xFFE2E8F0);
        badgeColor = dark ? AppColors.darkSurface : const Color(0xFFE2E8F0);
        badgeTextColor = dark ? AppColors.textWhite : AppColors.textPrimary;
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          splashColor: AppColors.primary.withValues(alpha: 0.12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: borderColor,
                width: (isChecked && (isCorrect || isSelected)) || isSelected
                    ? 2.0
                    : 1.5,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Option Letter Badge
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: badgeColor,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Center(
                    child: Text(
                      String.fromCharCode(65 + index),
                      style: TextStyle(
                        color: badgeTextColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Option Content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text.rich(
                      RichTextParser.parse(
                        optionTxt,
                        TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w400,
                          height: 1.5,
                          letterSpacing: 0.1,
                          color: dark
                              ? AppColors.textWhite
                              : AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ),

                // Outcome Icon
                if (isChecked) ...[
                  const SizedBox(width: 8),
                  if (isCorrect)
                    const Icon(
                      Icons.check_circle_rounded,
                      color: Color(0xFF10B981),
                      size: 22,
                    )
                  else if (isSelected)
                    const Icon(
                      Icons.cancel_rounded,
                      color: Color(0xFFEF4444),
                      size: 22,
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
