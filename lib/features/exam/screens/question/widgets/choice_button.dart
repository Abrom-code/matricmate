import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
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

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: isChecked
              ? (isCorrect
                    ? Colors.green.withValues(alpha: 0.15)
                    : isSelected
                    ? Colors.red.withValues(alpha: 0.15)
                    : dark
                    ? AppColors.darkChoice
                    : Colors.grey[100])
              : (isSelected
                    ? dark
                          ? const Color(0xFF1E3A42)
                          : const Color.fromARGB(255, 179, 195, 203)
                    : dark
                    ? AppColors.darkChoice
                    : Colors.grey[100]),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isChecked
                ? (isCorrect
                      ? Colors.green.withValues(alpha: 0.7)
                      : isSelected
                      ? Colors.red.withValues(alpha: 0.7)
                      : AppColors.darkGrey.withValues(alpha: 0.4))
                : (isSelected
                      ? Colors.green.withValues(alpha: 0.7)
                      : AppColors.darkGrey.withValues(alpha: 0.5)),
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: isChecked
                    ? (isCorrect
                          ? Colors.green
                          : isSelected
                          ? Colors.red
                          : dark
                          ? AppColors.darkerGrey
                          : const Color(0xFF8A8A8A))
                    : (isSelected
                          ? Colors.green
                          : dark
                          ? AppColors.darkerGrey
                          : const Color(0xFFA3A1A1)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  String.fromCharCode(65 + index),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text.rich(
                RichTextParser.parse(
                  optionTxt,
                  TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    height: 1.6,
                    letterSpacing: 0.1,
                    color: dark
                        ? const Color.fromARGB(255, 187, 187, 187)
                        : AppColors.darkerGrey,
                  ),
                ),
              ),
            ),

            ///  show correct/wrong
            if (isChecked)
              isCorrect
                  ? const Icon(Iconsax.tick_circle_copy, color: Colors.green)
                  : isSelected
                  ? const Icon(Iconsax.close_circle_copy, color: Colors.red)
                  : const SizedBox(),
          ],
        ),
      ),
    );
  }
}
