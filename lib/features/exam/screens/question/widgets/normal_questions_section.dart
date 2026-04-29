import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matricmate/features/exam/controllers/question_controller.dart';
import 'package:matricmate/features/exam/controllers/test_controller.dart';
import 'package:matricmate/features/exam/models/question_model.dart';
import 'package:matricmate/features/exam/models/result_model.dart';
import 'package:matricmate/features/exam/screens/question/widgets/choice_button.dart';
import 'package:matricmate/features/exam/screens/question/widgets/explanation_box.dart';
import 'package:matricmate/features/exam/screens/question/widgets/image_section.dart';
import 'package:matricmate/features/exam/screens/question/widgets/question_section.dart';
import 'package:matricmate/features/personalization/controller/user_controller.dart';
import 'package:matricmate/routes/app_routes.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/constants/sizes.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

class QuesitonSection extends GetView<QuestionController> {
  const QuesitonSection({super.key, required this.question});
  final QuestionModel question;
  @override
  Widget build(BuildContext context) {
    final dark = AppHelperFuntions.isDark(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSizes.defaultSpace,
        AppSizes.defaultSpace / 2,
        AppSizes.defaultSpace,
        AppSizes.defaultSpace,
      ),
      child: Obx(() {
        if (controller.testQuestions.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        final isChecked = controller.isAnswerChecked(question.id);
        final selectedIndex = controller.getSelectedAnswer(question.id);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quesition
            QuestionSection(
              qnNumber: question.questionOrder,
              examQn: question.questionText,
            ),
            const SizedBox(height: AppSizes.spaceBtwItems),

            // If there is Image
            if (question.imageUrl != null)
              ImageSection(imgUrl: question.imageUrl),
            if (question.imageUrl != null)
              const SizedBox(height: AppSizes.spaceBtwItems),

            // options
            ...question.options.asMap().entries.map((entry) {
              final index = entry.key;
              final option = entry.value;

              return ChoiceButton(
                selectedIndex: selectedIndex ?? -1,
                isChecked: isChecked,
                optionTxt: option,
                index: index,
                questionId: question.id,
                correctIndex: question.correctOptionIndex,
                onTap: () {
                  if (!isChecked) {
                    controller.selectAnswer(question.id, index);
                  }
                },
              );
            }),
            if (!controller.isAnswerChecked(question.id))
              const SizedBox(height: AppSizes.spaceBtwSections),
            if (controller.isAnswerChecked(question.id))
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
                      explanationEn: question.explanationEn,
                      explanationAm: question.explanationAm,
                    ),
                  if (controller.isExplanationExpanaded.value)
                    const SizedBox(height: 10),
                ],
              ),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 13),
                    ),
                    onPressed: controller.currentIndex.value > 0
                        ? () => controller.previousQuestion()
                        : null,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.arrow_left),
                        Text(
                          "Previous",
                          style: TextStyle(
                            color: !dark
                                ? null
                                : !dark
                                ? null
                                : !(controller.currentIndex.value > 0)
                                ? AppColors.darkGrey
                                : AppColors.grey,
                          ),
                        ),
                      ],
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
                    final currentSelected = controller.getSelectedAnswer(q.id);

                    return OutlinedButton(
                      onPressed: currentSelected == null
                          ? null
                          : () async {
                              if (!isChecked) {
                                controller.checkAnswer(q.id);
                              } else {
                                if (isLast) {
                                  final result = ResultModel(
                                    userId:
                                        UserController.instance.user.value.id,
                                    testId: question.testId,
                                    selectedAnswers: controller.selectedAnswers,
                                    testQuestions: controller.testQuestions
                                        .toList(),
                                    correctAnswers: controller.correctAnswers,
                                  );
                                  controller.saveResult(result);
                                  TestController.instance.testResults[result
                                          .testId] =
                                      result;
                                  Get.offNamed(
                                    Routes.result,
                                    arguments: {'result': result},
                                  );
                                } else {
                                  controller.nextQuestion();
                                }
                              }
                            },
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 13),
                      ),
                      child: !isChecked
                          ? Text(
                              "Check Answer",
                              style: TextStyle(
                                color: !dark
                                    ? null
                                    : currentSelected == null
                                    ? AppColors.darkGrey
                                    : AppColors.grey,
                              ),
                            )
                          : (isLast
                                ? Text(
                                    "Finished",
                                    style: TextStyle(
                                      color: !dark ? null : AppColors.grey,
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        "Next",
                                        style: TextStyle(
                                          color: !dark ? null : AppColors.grey,
                                        ),
                                      ),
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
      }),
    );
  }
}
