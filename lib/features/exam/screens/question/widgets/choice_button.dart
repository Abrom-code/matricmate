import 'package:flutter/material.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

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
    final dark = AppHelperFuntions.isDark(context);
    final isSelected = selectedIndex == index;
    final isCorrect = index == correctIndex;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 10),
        decoration: BoxDecoration(
          color: isChecked
              ? (isCorrect
                    ? Colors.green.withValues(alpha: 0.2)
                    : isSelected
                    ? Colors.red.withValues(alpha: 0.2)
                    : dark
                    ? AppColors.darkerGrey.withValues(alpha: 0.3)
                    : Colors.grey[300])
              : (isSelected
                    ? const Color.fromARGB(255, 115, 134, 144)
                    : dark
                    ? AppColors.darkerGrey.withValues(alpha: 0.3)
                    : Colors.grey[300]),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isChecked
                ? (isCorrect
                      ? Colors.green.withValues(alpha: 0.7)
                      : isSelected
                      ? Colors.red.withValues(alpha: 0.7)
                      : Colors.grey.withValues(alpha: 0.7))
                : (isSelected
                      ? Colors.green.withValues(alpha: 0.7)
                      : Colors.grey.withValues(alpha: 0.7)),
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
                          ? Colors.black
                          : const Color.fromARGB(255, 109, 109, 109))
                    : (isSelected
                          ? Colors.green
                          : dark
                          ? Colors.black
                          : const Color.fromARGB(255, 109, 109, 109)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  String.fromCharCode(65 + index),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                optionTxt,
                style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                  fontSize: 17,
                  color: dark
                      ? const Color.fromARGB(255, 187, 187, 187)
                      : AppColors.darkerGrey,
                ),
              ),
            ),

            ///  show correct/wrong
            if (isChecked)
              isCorrect
                  ? const Icon(Icons.check_circle, color: Colors.green)
                  : isSelected
                  ? const Icon(Icons.cancel, color: Colors.red)
                  : const SizedBox(),
          ],
        ),
      ),
    );
  }
}
