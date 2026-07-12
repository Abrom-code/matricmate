import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matricmate/common/widgets/loaders/circular_loading.dart';
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

    // Mark submitted BEFORE saving so onClose doesn't overwrite with a draft.
    controller.markSubmitted();

    final result = ResultModel(
      userId: UserController.instance.user.value.id,
      testId: q.testId,
      selectedAnswers: controller.selectedAnswers,
      testQuestions: controller.testQuestions.toList(),
      correctAnswers: controller.correctAnswers,
      isCompleted: true,
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
          return const Center(child: AppPulsingDots());
        }

        final q = controller.testQuestions[controller.currentIndex.value];
        final examMode = controller.isExamMode;

        final isChecked = controller.isAnswerChecked(q.id);
        final selectedIndex = controller.getSelectedAnswer(q.id);
        final isLast =
            controller.currentIndex.value ==
            controller.testQuestions.length - 1;

        // In practice mode: Skip shown when not yet answered and not last.
        // In exam mode: Skip shown when no option selected (unanswered), so
        // the user can move on without committing; once an option is selected
        // the button becomes Next/Finish.
        final canSkip = examMode
            ? selectedIndex == null
            : !isChecked && !isLast;

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
                        if (!isChecked) {
                          controller.selectAnswer(q.id, index);
                          controller.checkAnswer(q.id);
                        }
                      },
              );
            }),

            /// EXPLANATION — practice mode only, after checking
            if (isChecked && !examMode) ...[
              ExplanationBox(
                explanationEn: q.explanationEn,
                explanationAm: q.explanationAm,
                explanationImageUrl: q.explanationImageUrl,
              ),
              const SizedBox(height: AppSizes.spaceBtwItems),
            ] else
              const SizedBox(height: AppSizes.xs),

            /// BUTTONS — always two: Prev | (Skip or Next/Finish)
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

                /// SKIP — when no answer selected in exam mode (any question),
                ///         or when not yet answered in practice mode (non-last)
                /// NEXT / FINISH — after option selected (exam) or checked (practice)
                Expanded(
                  child: canSkip
                      ? OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            foregroundColor: AppColors.darkGrey,
                            side: BorderSide(
                              color: AppColors.darkGrey.withValues(alpha: 0.4),
                            ),
                          ),
                          onPressed: examMode
                              ? () async {
                                  // In exam mode, Skip on last question = Finish
                                  if (isLast) {
                                    await _submitResult(context, q);
                                  } else {
                                    controller.skipQuestion();
                                  }
                                }
                              : controller.skipQuestion,
                          icon: Icon(
                            examMode && isLast
                                ? Icons.flag_rounded
                                : Icons.skip_next_rounded,
                            size: 16,
                          ),
                          label: Text(
                            examMode && isLast ? 'Finish' : 'Skip',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        )
                      : OutlinedButton.icon(
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
                              : !isChecked
                              ? null
                              : () async {
                                  if (isLast) {
                                    await _submitResult(context, q);
                                  } else {
                                    controller.nextQuestion();
                                  }
                                },
                          icon: Icon(
                            isLast
                                ? Icons.flag_rounded
                                : Icons.arrow_forward_ios_rounded,
                            size: 15,
                          ),
                          label: Text(
                            isLast ? 'Finish' : 'Next',
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
