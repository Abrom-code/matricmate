import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matricmate/features/exam/controllers/question_controller.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

class ChoiceButton extends StatelessWidget {
  const ChoiceButton({
    super.key,
    required this.optionTxt,
    required this.index,
    required this.questionId,
    required this.correctIndex,
  });

  final String optionTxt;
  final int index;
  final int questionId;
  final int correctIndex;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<QuestionController>();
    final dark = AppHelperFuntions.isDark(context);

    return Obx(() {
      final isChecked = controller.isAnswerChecked(questionId);
      final selectedIndex = controller.getSelectedAnswer(questionId);

      final isSelected = selectedIndex == index;
      final isCorrect = index == correctIndex;

      return GestureDetector(
        onTap: () {
          if (!isChecked) {
            controller.selectAnswer(questionId, index);
          }
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isChecked
                ? (isCorrect
                      ? Colors.green.withValues(alpha: 0.2)
                      : isSelected
                      ? Colors.red.withValues(alpha: 0.2)
                      : dark
                      ? AppColors.darkerGrey
                      : Colors.grey[300])
                : (isSelected
                      ? const Color.fromARGB(255, 115, 134, 144)
                      : dark
                      ? AppColors.darkerGrey
                      : Colors.grey[300]),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isChecked
                  ? (isCorrect
                        ? Colors.green
                        : isSelected
                        ? Colors.red
                        : Colors.grey)
                  : (isSelected ? Colors.green : Colors.grey),
              width: 2,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 25,
                height: 25,
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
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  optionTxt,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
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
    });
  }
}
