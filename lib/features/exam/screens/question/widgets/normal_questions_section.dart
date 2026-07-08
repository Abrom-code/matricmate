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

  // ── shared submit helper ────────────────────────────────────────────────────
  Future<void> _submitResult(BuildContext context, QuestionModel q) async {
    // In exam mode, mark every unanswered question as checked now so the
    // result screen can compute the score properly.
    if (controller.isExamMode) {
      for (final tq in controller.testQuestions) {
        controller.checkAnswer(tq.id);
      }
    }

    final result = ResultModel(
      userId: UserController.instance.user.value.id,
      testId: q.testId,
      selectedAnswers: controller.selectedAnswers,
      testQuestions: controller.testQuestions.toList(),
      correctAnswers: controller.correctAnswers,
    );

    await controller.saveResult(result);

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

    Get.offNamed(Routes.result, arguments: {'result': result});
  }

  // ───────────────────────────────────────────────────────────────────────────

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
        final examMode = controller.isExamMode;

        final isChecked = controller.isAnswerChecked(q.id);
        final selectedIndex = controller.getSelectedAnswer(q.id);
        final isLast =
            controller.currentIndex.value ==
            controller.testQuestions.length - 1;

        // Skip is available in practice mode only (not yet checked, not last).
        // In exam mode Next already advances without requiring an answer,
        // so a separate Skip button would be redundant.
        final canSkip = !examMode && !isChecked && !isLast;

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
                // in exam mode, never show green/red reveal colours
                isChecked: examMode ? false : isChecked,
                optionTxt: option,
                index: index,
                questionId: q.id,
                correctIndex: q.correctOptionIndex,
                onTap: examMode
                    ? () => controller.selectAnswer(q.id, index)
                    : () {
                        if (!isChecked) controller.selectAnswer(q.id, index);
                      },
              );
            }),

            /// EXPLANATION — practice mode only, after checking
            if (isChecked && !examMode) ...[
              ExplanationBox(
                explanationEn: q.explanationEn,
                explanationAm: q.explanationAm,
              ),
              const SizedBox(height: AppSizes.spaceBtwItems),
            ] else
              const SizedBox(height: AppSizes.xs),

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
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 14,
                    ),
                    label: const Text(
                      'Prev',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),

                const SizedBox(width: 8),

                /// SKIP — centre slot
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
                    onPressed: examMode
                        ? () async {
                            if (isLast) {
                              await _submitResult(context, q);
                            } else {
                              controller.nextQuestion();
                            }
                          }
                        : selectedIndex == null
                        ? null
                        : () async {
                            if (!isChecked) {
                              controller.checkAnswer(q.id);
                              return;
                            }
                            if (isLast) {
                              await _submitResult(context, q);
                            } else {
                              controller.nextQuestion();
                            }
                          },
                    icon: Icon(
                      examMode
                          ? (isLast
                              ? Icons.flag_rounded
                              : Icons.arrow_forward_ios_rounded)
                          : !isChecked
                          ? Icons.check_circle_outline_rounded
                          : (isLast
                              ? Icons.flag_rounded
                              : Icons.arrow_forward_ios_rounded),
                      size: 15,
                    ),
                    label: Text(
                      examMode
                          ? (isLast ? 'Finish' : 'Next')
                          : !isChecked
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
