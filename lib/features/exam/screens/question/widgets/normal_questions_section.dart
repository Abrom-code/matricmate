import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matricmate/features/exam/controllers/chapter_test_controller.dart';
import 'package:matricmate/features/exam/controllers/entrance_exams_controller.dart';
import 'package:matricmate/features/exam/controllers/grade_test_controller.dart';
import 'package:matricmate/features/exam/controllers/question_controller.dart';
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

class QuesitonSection extends GetView<QuestionController> {
  const QuesitonSection({super.key, required this.question});
  final QuestionModel question;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.defaultSpace,
        AppSizes.defaultSpace / 2,
        AppSizes.defaultSpace,
        AppSizes.defaultSpace,
      ),
      child: Obx(() {
        if (controller.testQuestions.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        final q = controller.testQuestions[controller.currentIndex.value];

        final isChecked = controller.isAnswerChecked(q.id);
        final selectedIndex = controller.getSelectedAnswer(q.id);
        final isLast =
            controller.currentIndex.value ==
            controller.testQuestions.length - 1;
        final canSkip = !isChecked && !isLast;

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
                          'Explanation',
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

            /// BUTTONS — Previous | Skip | Check/Next/Finish
            Row(
              children: [
                /// PREVIOUS
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                    onPressed: controller.currentIndex.value > 0
                        ? controller.previousQuestion
                        : null,
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 14),
                    label: const Text(
                      'Prev',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                /// SKIP — centre slot, only when no answer & not last
                if (canSkip) ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        foregroundColor: AppColors.darkGrey,
                        side: BorderSide(
                          color: AppColors.darkGrey.withValues(alpha: 0.4),
                        ),
                      ),
                      onPressed: controller.skipQuestion,
                      icon: const Icon(Icons.skip_next_rounded, size: 16),
                      label: const Text(
                        'Skip',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],

                /// NEXT / CHECK / FINISH
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 13),
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
                              // grade test   id:0
                              // chapter test id:1
                              // exam         id:2
                              switch (controller.ctrlId) {
                                case 0:
                                  final c = Get.find<GradeTestController>();
                                  await c.loadTestResults(c.chapterTests);
                                case 1:
                                  final c = Get.find<ChapterTestController>();
                                  await c.loadTestResults(c.chapterTest);
                                case 2:
                                  final c = Get.find<ExamsController>();
                                  await c.loadTestResults(c.entranceTests);
                                default:
                                  break;
                              }
                              Get.offNamed(
                                Routes.result,
                                arguments: {'result': result},
                              );
                            } else {
                              controller.nextQuestion();
                            }
                          },
                    icon: Icon(
                      !isChecked
                          ? Icons.check_circle_outline_rounded
                          : (isLast
                              ? Icons.flag_rounded
                              : Icons.arrow_forward_ios_rounded),
                      size: 15,
                    ),
                    label: Text(
                      !isChecked
                          ? 'Check'
                          : (isLast ? 'Finish' : 'Next'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
