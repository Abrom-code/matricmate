import 'package:flutter/material.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';
import 'package:get/get_state_manager/src/simple/get_view.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:matricmate/features/exam/controllers/review_controller.dart';
import 'package:matricmate/features/exam/models/question_model.dart';
import 'package:matricmate/features/exam/models/result_model.dart';
import 'package:matricmate/features/exam/screens/question/widgets/choice_button.dart';
import 'package:matricmate/features/exam/screens/question/widgets/image_section.dart';
import 'package:matricmate/features/exam/screens/question/widgets/question_section.dart';
import 'package:matricmate/features/exam/screens/result/widgets/correct_check_button.dart';
import 'package:matricmate/features/exam/screens/result/widgets/explanation_button.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/constants/sizes.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

class ReviewContainer extends GetView<ReviewController> {
  const ReviewContainer({super.key, required this.qn, required this.result});
  final QuestionModel qn;
  final ResultModel result;

  @override
  Widget build(BuildContext context) {
    final dark = AppHelperFuntions.isDark(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppSizes.defaultSpace / 1.3),
      decoration: BoxDecoration(
        color: dark
            ? AppColors.darkerGrey.withValues(alpha: 0.5)
            : Color(0xFFe7eae7),
        borderRadius: BorderRadius.circular(AppSizes.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          //qn number and result
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "${qn.questionOrder} of ${result.testQuestions.length}",
                style: Theme.of(
                  context,
                ).textTheme.labelMedium!.apply(fontSizeDelta: 3),
              ),
              result.selectedAnswers[qn.id] == null
                  ? CorrectCheckButton(
                      color: dark ? AppColors.darkGrey : AppColors.darkerGrey,
                      icon: Iconsax.timer_1_copy,
                      text: "Not Answered",
                    )
                  : result.selectedAnswers[qn.id] == qn.correctOptionIndex
                  ? CorrectCheckButton()
                  : CorrectCheckButton(
                      color: Colors.red,
                      icon: Iconsax.close_circle_copy,
                      text: "incorrect",
                    ),
            ],
          ),
          Divider(height: AppSizes.lg),
          // qn txt
          QuestionSection(qnNumber: qn.questionOrder, examQn: qn.questionText),
          const SizedBox(height: AppSizes.spaceBtwItems),

          // If there is Image
          if (qn.imageUrl != null) ImageSection(imgUrl: qn.imageUrl),
          if (qn.imageUrl != null)
            const SizedBox(height: AppSizes.spaceBtwItems),
          // Options
          ...qn.options.asMap().entries.map((entry) {
            final index = entry.key;
            final option = entry.value;

            return ChoiceButton(
              isChecked: true,
              selectedIndex: result.selectedAnswers[qn.id] ?? -1,
              optionTxt: option,
              index: index,
              questionId: qn.id,
              correctIndex: qn.correctOptionIndex,
            );
          }),
          const SizedBox(height: AppSizes.spaceBtwItems),

          // Explanation button
          Obx(() {
            final expanded = controller.isExpanded[qn.id] ?? false;
            return ExplanationButton(
              expanded: expanded,
              dark: dark,
              controller: controller,
              qn: qn,
            );
          }),
        ],
      ),
    );
  }
}
