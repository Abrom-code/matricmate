import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:matricmate/common/widgets/exam/question_detail_box.dart';
import 'package:matricmate/features/exam/controllers/review_controller.dart';
import 'package:matricmate/features/exam/models/question_model.dart';
import 'package:matricmate/features/exam/models/result_model.dart';
import 'package:matricmate/features/exam/screens/result/widgets/correct_check_button.dart';
import 'package:matricmate/utils/constants/colors.dart';

class ReviewContainer extends GetView<ReviewController> {
  const ReviewContainer({super.key, required this.qn, required this.result});
  final QuestionModel qn;
  final ResultModel result;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final passageExpanded = controller.isPassageExpanded[qn.id] ?? false;
      final passage = qn.passageId != null
          ? controller.passages[qn.passageId]
          : null;
      final explanationExpanded = controller.isExpanded[qn.id] ?? false;
      final selectedAnswer = result.selectedAnswers[qn.id] ?? -1;

      return QuestionDetailBox(
        question: qn,
        selectedAnswerIndex: selectedAnswer,
        // ── Header ───────────────────────────────────────────────────
        headerLeft: Text(
          '${qn.questionOrder} of ${result.testQuestions.length}',
          style: Theme.of(context)
              .textTheme
              .labelMedium!
              .apply(fontSizeDelta: 3),
        ),
        headerRight: result.selectedAnswers[qn.id] == null
            ? CorrectCheckButton(
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.darkGrey
                    : AppColors.darkerGrey,
                icon: Iconsax.timer_1_copy,
                text: 'Not Answered',
              )
            : result.selectedAnswers[qn.id] == qn.correctOptionIndex
                ? const CorrectCheckButton()
                : const CorrectCheckButton(
                    color: Colors.red,
                    icon: Iconsax.close_circle_copy,
                    text: 'Incorrect',
                  ),
        // ── Passage ──────────────────────────────────────────────────
        passageTitle: passage?.title,
        passageContent: passage?.content,
        passageExpanded: passageExpanded,
        onPassageToggle: () => controller.togglePassage(qn.id),
        // ── Explanation ───────────────────────────────────────────────
        explanationExpanded: explanationExpanded,
        onExplanationToggle: () => controller.toggle(qn.id),
        languageSelected: controller.languageSelected,
        onLanguageChange: (v) => controller.languageSelected.value = v,
      );
    });
  }
}
