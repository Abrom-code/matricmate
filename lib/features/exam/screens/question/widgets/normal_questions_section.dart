import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matricmate/features/exam/controllers/question_controller.dart';
import 'package:matricmate/features/exam/controllers/test_controller.dart';
import 'package:matricmate/features/exam/models/result_model.dart';
import 'package:matricmate/features/exam/screens/question/widgets/choice_button.dart';
import 'package:matricmate/features/exam/screens/question/widgets/explanation_box.dart';
import 'package:matricmate/features/exam/screens/question/widgets/image_section.dart';
import 'package:matricmate/features/exam/screens/question/widgets/question_section.dart';
import 'package:matricmate/features/exam/screens/result/result.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/constants/sizes.dart';

class NormarQuesionsSection extends GetView<QuestionController> {
  const NormarQuesionsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.testQuestions.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }

      final examQn = controller.testQuestions[controller.currentIndex.value];

      final isChecked = controller.isAnswerChecked(examQn.id);
      final selectedIndex = controller.getSelectedAnswer(examQn.id);

      return Column(
        children: [
          // Quesition
          QuestionSection(
            qnNumber: examQn.questionOrder,
            examQn: examQn.questionText,
          ),
          const SizedBox(height: AppSizes.spaceBtwItems),

          // If there is Image
          if (examQn.imageUrl != null) ImageSection(imgUrl: examQn.imageUrl),
          if (examQn.imageUrl != null)
            const SizedBox(height: AppSizes.spaceBtwItems),

          // options
          ...examQn.options.asMap().entries.map((entry) {
            final index = entry.key;
            final option = entry.value;

            return ChoiceButton(
              selectedIndex: selectedIndex ?? -1,
              isChecked: isChecked,
              optionTxt: option,
              index: index,
              questionId: examQn.id,
              correctIndex: examQn.correctOptionIndex,
              onTap: () {
                if (!isChecked) {
                  controller.selectAnswer(examQn.id, index);
                }
              },
            );
          }),
          const SizedBox(height: AppSizes.spaceBtwItems),
          if (controller.isAnswerChecked(examQn.id))
            Column(
              children: [
                // explanations
                TextButton(
                  onPressed: () => controller.isExplanationExpanaded.value =
                      !controller.isExplanationExpanaded.value,
                  child: Row(
                    children: [
                      Icon(
                        controller.isExplanationExpanaded.value
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_right,
                        color: AppColors.primary,
                        size: 24,
                      ),
                      Text(
                        "Explanation",
                        style: Theme.of(context).textTheme.titleMedium!.apply(
                          color: AppColors.primary,
                          fontSizeDelta: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),

                if (controller.isExplanationExpanaded.value)
                  ExplanationBox(
                    explanationEn: examQn.explanationEn,
                    explanationAm: examQn.explanationAm,
                  ),

                // Next/check answer button
                const SizedBox(height: AppSizes.spaceBtwItems),
              ],
            ),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: controller.currentIndex.value > 0
                      ? () => controller.previousQuestion()
                      : null,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [Icon(Icons.arrow_left), Text("Previous")],
                  ),
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Obx(() {
                  final q =
                      controller.testQuestions[controller.currentIndex.value];
                  final isChecked = controller.isAnswerChecked(q.id);

                  final isLast =
                      controller.currentIndex.value ==
                      controller.testQuestions.length - 1;

                  return OutlinedButton(
                    onPressed: () async {
                      if (!isChecked) {
                        controller.checkAnswer(q.id);
                      } else {
                        if (isLast) {
                          final result = ResultModel(
                            testId: examQn.testId,
                            selectedAnswers: controller.selectedAnswers,
                            testQuestions: controller.testQuestions.toList(),
                            correctAnswers: controller.correctAnswers,
                          );
                          controller.saveResult(result);
                          TestController.instance.testResults[result.testId] =
                              result;
                          Get.offAll(() => ResultScreen(result: result));
                        } else {
                          controller.nextQuestion();
                        }
                      }
                    },
                    child: !isChecked
                        ? Text("Check Answer")
                        : (isLast
                              ? Text("Finished")
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text("Next"),
                                    Icon(Icons.arrow_right),
                                  ],
                                )),
                  );
                }),
              ),
            ],
          ),
        ],
      );
    });
  }
}
