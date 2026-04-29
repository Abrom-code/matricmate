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

        // 🔥 ALWAYS use current question from controller
        final q = controller.testQuestions[controller.currentIndex.value];

        final isChecked = controller.isAnswerChecked(q.id);
        final selectedIndex = controller.getSelectedAnswer(q.id);
        final isLast =
            controller.currentIndex.value ==
            controller.testQuestions.length - 1;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// QUESTION
            QuestionSection(qnNumber: q.questionOrder, examQn: q.questionText),
            const SizedBox(height: AppSizes.spaceBtwItems),

            /// IMAGE
            if (q.imageUrl != null) ImageSection(imgUrl: q.imageUrl),
            if (q.imageUrl != null)
              const SizedBox(height: AppSizes.spaceBtwItems),

            /// OPTIONS
            ...q.options.asMap().entries.map((entry) {
              final index = entry.key;
              final option = entry.value;

              return ChoiceButton(
                selectedIndex: selectedIndex ?? -1,
                isChecked: isChecked,
                optionTxt: option,
                index: index,
                questionId: q.id,
                correctIndex: q.correctOptionIndex,
                onTap: () {
                  if (!isChecked) {
                    controller.selectAnswer(q.id, index);
                  }
                },
              );
            }),

            if (!isChecked) const SizedBox(height: AppSizes.spaceBtwItems),

            /// EXPLANATION
            if (isChecked)
              Column(
                children: [
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
                        ),
                        Text(
                          "Explanation",
                          style: Theme.of(context).textTheme.titleMedium!.apply(
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (controller.isExplanationExpanaded.value)
                    ExplanationBox(
                      explanationEn: q.explanationEn,
                      explanationAm: q.explanationAm,
                    ),
                ],
              ),
            if (isChecked) const SizedBox(height: AppSizes.spaceBtwItems / 2),
            if (!isChecked) const SizedBox(height: AppSizes.spaceBtwItems),

            /// BUTTONS
            Row(
              children: [
                /// PREVIOUS
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.all(13),
                    ),
                    onPressed: controller.currentIndex.value > 0
                        ? controller.previousQuestion
                        : null,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.arrow_left),
                        Text(
                          "Previous",
                          style: TextStyle(
                            color: dark
                                ? controller.currentIndex.value <= 0
                                      ? AppColors.darkGrey
                                      : null
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                /// NEXT / CHECK / FINISH
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.all(13),
                    ),
                    onPressed: selectedIndex == null
                        ? null
                        : () async {
                            if (!isChecked) {
                              controller.checkAnswer(q.id);
                              return;
                            }

                            if (isLast) {
                              final result = ResultModel(
                                userId: UserController.instance.user.value.id,
                                testId: q.testId,
                                selectedAnswers: controller.selectedAnswers,
                                testQuestions: controller.testQuestions
                                    .toList(),
                                correctAnswers: controller.correctAnswers,
                              );

                              await controller.saveResult(result);

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
                          },
                    child: Text(
                      !isChecked
                          ? "Check Answer"
                          : (isLast ? "Finished" : "Next"),
                      style: TextStyle(
                        color: dark
                            ? selectedIndex == null
                                  ? AppColors.darkGrey
                                  : null
                            : null,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      }),
    );
  }
}
