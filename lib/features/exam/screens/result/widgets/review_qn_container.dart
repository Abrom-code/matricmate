import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matricmate/common/widgets/exam/question_detail_box.dart';
import 'package:matricmate/features/exam/controllers/review_controller.dart';
import 'package:matricmate/features/exam/models/question_model.dart';
import 'package:matricmate/features/exam/models/result_model.dart';
import 'package:matricmate/features/exam/screens/result/widgets/correct_check_button.dart';
import 'package:matricmate/utils/constants/colors.dart';

class ReviewContainer extends StatefulWidget {
  const ReviewContainer({super.key, required this.qn, required this.result});
  final QuestionModel qn;
  final ResultModel result;

  @override
  State<ReviewContainer> createState() => _ReviewContainerState();
}

class _ReviewContainerState extends State<ReviewContainer>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final controller = ReviewController.instance;

    return Obx(() {
      final passageExpanded =
          controller.isPassageExpanded[widget.qn.id] ?? false;
      final passage = widget.qn.passageId != null
          ? controller.passages[widget.qn.passageId]
          : null;
      final explanationExpanded = controller.isExpanded[widget.qn.id] ?? false;
      final selectedAnswer =
          widget.result.selectedAnswers[widget.qn.id] ?? -1;

      return QuestionDetailBox(
        question: widget.qn,
        selectedAnswerIndex: selectedAnswer,
        // ── Header ───────────────────────────────────────────────────
        headerLeft: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'Q${widget.qn.questionOrder} of ${widget.result.testQuestions.length}',
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
              fontSize: 12.5,
            ),
          ),
        ),
        headerRight: widget.result.selectedAnswers[widget.qn.id] == null
            ? const CorrectCheckButton(
                color: Color(0xFFF59E0B),
                icon: Icons.timer_outlined,
                text: 'Skipped',
              )
            : widget.result.selectedAnswers[widget.qn.id] ==
                    widget.qn.correctOptionIndex
            ? const CorrectCheckButton(
                color: Color(0xFF10B981),
                icon: Icons.check_circle_rounded,
                text: 'Correct',
              )
            : const CorrectCheckButton(
                color: Color(0xFFEF4444),
                icon: Icons.cancel_rounded,
                text: 'Wrong',
              ),
        // ── Passage ──────────────────────────────────────────────────
        passageTitle: passage?.title,
        passageContent: passage?.content,
        passageExpanded: passageExpanded,
        onPassageToggle: () => controller.togglePassage(widget.qn.id),
        // ── Explanation ───────────────────────────────────────────────
        explanationExpanded: explanationExpanded,
        onExplanationToggle: () => controller.toggle(widget.qn.id),
        languageSelected: controller.languageSelected,
        onLanguageChange: (v) => controller.languageSelected.value = v,
      );
    });
  }
}
