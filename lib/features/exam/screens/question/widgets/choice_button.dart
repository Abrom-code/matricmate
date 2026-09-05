import 'package:flutter/material.dart';
import 'package:matricmate/common/widgets/exam/bb_table_widget.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/helpers/bb_table_parser.dart';
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
    Color badgeBgColor;
    Color badgeBorderColor;
    Color badgeTextColor;

    if (isChecked) {
      if (isCorrect) {
        bgColor = const Color(0xFF10B981).withValues(alpha: dark ? 0.14 : 0.07);
        borderColor = const Color(0xFF10B981);
        badgeBgColor = const Color(0xFF10B981);
        badgeBorderColor = const Color(0xFF10B981);
        badgeTextColor = Colors.white;
      } else if (isSelected) {
        bgColor = const Color(0xFFEF4444).withValues(alpha: dark ? 0.14 : 0.07);
        borderColor = const Color(0xFFEF4444);
        badgeBgColor = const Color(0xFFEF4444);
        badgeBorderColor = const Color(0xFFEF4444);
        badgeTextColor = Colors.white;
      } else {
        bgColor = dark ? AppColors.darkCard.withValues(alpha: 0.5) : Colors.white;
        borderColor = dark ? AppColors.darkBorder : const Color(0xFFE2E8F0);
        badgeBgColor = Colors.transparent;
        badgeBorderColor = dark ? AppColors.darkBorder : const Color(0xFFCBD5E1);
        badgeTextColor = dark ? AppColors.darkGrey : AppColors.textSecondary;
      }
    } else {
      if (isSelected) {
        bgColor = AppColors.primary.withValues(alpha: dark ? 0.15 : 0.06);
        borderColor = AppColors.primary;
        badgeBgColor = AppColors.primary;
        badgeBorderColor = AppColors.primary;
        badgeTextColor = Colors.white;
      } else {
        bgColor = dark ? AppColors.darkCard.withValues(alpha: 0.5) : Colors.white;
        borderColor = dark ? AppColors.darkBorder : const Color(0xFFE2E8F0);
        badgeBgColor = Colors.transparent;
        badgeBorderColor = dark ? AppColors.darkBorder : const Color(0xFFCBD5E1);
        badgeTextColor = dark ? AppColors.textWhite : AppColors.textPrimary;
      }
    }

    final textStyle = TextStyle(
      fontSize: 15,
      fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
      height: 1.45,
      letterSpacing: 0.1,
      color: dark ? AppColors.textWhite : AppColors.textPrimary,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          splashColor: AppColors.primary.withValues(alpha: 0.08),
          highlightColor: AppColors.primary.withValues(alpha: 0.04),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 13),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: borderColor,
                width: isSelected || (isChecked && (isCorrect || isSelected))
                    ? 1.8
                    : 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: isSelected
                      ? AppColors.primary.withValues(alpha: dark ? 0.15 : 0.08)
                      : (dark
                            ? Colors.black.withValues(alpha: 0.15)
                            : const Color(0x08000000)),
                  blurRadius: isSelected ? 8 : 3,
                  offset: const Offset(0, 1.5),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Circular Option Badge
                AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: badgeBgColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: badgeBorderColor,
                      width: 1.4,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      String.fromCharCode(65 + index),
                      style: TextStyle(
                        color: badgeTextColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Option Content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 1.5),
                    child: _buildOptionContent(textStyle),
                  ),
                ),

                // Outcome Icon
                if (isChecked) ...[
                  const SizedBox(width: 8),
                  if (isCorrect)
                    const Padding(
                      padding: EdgeInsets.only(top: 3),
                      child: Icon(
                        Icons.check_circle_rounded,
                        color: Color(0xFF10B981),
                        size: 22,
                      ),
                    )
                  else if (isSelected)
                    const Padding(
                      padding: EdgeInsets.only(top: 3),
                      child: Icon(
                        Icons.cancel_rounded,
                        color: Color(0xFFEF4444),
                        size: 22,
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOptionContent(TextStyle textStyle) {
    if (!BBTableParser.containsTable(optionTxt)) {
      return Text.rich(
        RichTextParser.parse(optionTxt, textStyle),
      );
    }

    final segments = BBTableParser.splitSegments(optionTxt);
    final widgets = <Widget>[];

    for (final seg in segments) {
      if (seg.isTable) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: BBTableWidget(
              rows: seg.tableRows!,
              baseStyle: textStyle.copyWith(fontSize: 13.5),
              minWidth: 0,
            ),
          ),
        );
      } else {
        widgets.add(
          Text.rich(
            RichTextParser.parse(seg.text!, textStyle),
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: widgets,
    );
  }
}
