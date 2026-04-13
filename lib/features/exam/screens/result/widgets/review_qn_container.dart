import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/src/extension_instance.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';
import 'package:get/get_state_manager/src/simple/get_view.dart';
import 'package:matricmate/features/exam/controllers/question_controller.dart';
import 'package:matricmate/features/exam/controllers/review_controller.dart';
import 'package:matricmate/features/exam/models/question_model.dart';
import 'package:matricmate/features/exam/screens/question/widgets/choice_button.dart';
import 'package:matricmate/features/exam/screens/question/widgets/question_section.dart';
import 'package:matricmate/features/exam/screens/result/widgets/correct_check_button.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/constants/sizes.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

class ReviewContainer extends GetView<QuestionController> {
  const ReviewContainer({super.key, required this.qn});
  final QuestionModel qn;

  @override
  Widget build(BuildContext context) {
    final dark = AppHelperFuntions.isDark(context);
    final reviewController = Get.put(ReviewController());
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppSizes.defaultSpace),
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
                "Quesion ${qn.questionOrder} of ${controller.testQuestions.length}",
                style: Theme.of(
                  context,
                ).textTheme.labelMedium!.apply(fontSizeDelta: 3),
              ),
              controller.selectedAnswers[qn.id] == qn.correctOptionIndex
                  ? CorrectCheckButton()
                  : CorrectCheckButton(
                      color: Colors.red,
                      icon: Icons.cancel_rounded,
                      text: "incorrect",
                    ),
            ],
          ),
          Divider(height: AppSizes.lg),
          // qn txt
          QuestionSection(qnNumber: qn.questionOrder, examQn: qn.questionText),
          const SizedBox(height: AppSizes.spaceBtwItems),

          // Options
          ...qn.options.asMap().entries.map((entry) {
            final index = entry.key;
            final option = entry.value;

            return ChoiceButton(
              optionTxt: option,
              index: index,
              questionId: qn.id,
              correctIndex: qn.correctOptionIndex,
            );
          }),
          const SizedBox(height: AppSizes.spaceBtwItems),

          // Explanation button
          Obx(() {
            final expanded = reviewController.isExpanded[qn.id] ?? false;
            return Container(
              width: double.infinity,
              padding: expanded
                  ? EdgeInsets.only(
                      bottom: AppSizes.md,
                      right: AppSizes.md,
                      left: AppSizes.md,
                      top: 0,
                    )
                  : EdgeInsets.symmetric(horizontal: AppSizes.md),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppSizes.sm),
                color: dark ? AppColors.black : AppColors.white,
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: TextButton(
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.all(5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                          onPressed: () => reviewController.toggle(qn.id),
                          child: Row(
                            mainAxisAlignment: !expanded
                                ? MainAxisAlignment.spaceBetween
                                : MainAxisAlignment.start,
                            children: [
                              Text(
                                "Why this is correct?",
                                style: Theme.of(context).textTheme.bodyLarge!
                                    .copyWith(color: AppColors.primary),
                              ),
                              Icon(
                                expanded
                                    ? Icons.arrow_right
                                    : Icons.arrow_drop_down,
                                color: AppColors.primary,
                              ),
                            ],
                          ),
                        ),
                      ),

                      if (expanded)
                        DropdownButton<String>(
                          padding: EdgeInsets.all(0),
                          isDense: true,
                          iconEnabledColor: AppColors.primary,
                          underline: SizedBox(),
                          value: controller.languageSelected.toString(),
                          items: [
                            DropdownMenuItem(
                              value: 'EN',
                              child: Text(
                                "EN",
                                style: Theme.of(context).textTheme.bodyMedium!
                                    .copyWith(color: AppColors.primary),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'AM',
                              child: Text(
                                "AM",
                                style: Theme.of(context).textTheme.bodyMedium!
                                    .copyWith(color: AppColors.primary),
                              ),
                            ),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              controller.languageSelected.value = val;
                            }
                          },
                        ),
                    ],
                  ),
                  if (expanded)
                    Column(
                      children: [
                        Divider(),
                        Text(
                          textAlign: TextAlign.justify,
                          controller.languageSelected.value == "EN"
                              ? qn.explanationEn
                              : qn.explanationAm,
                          style: Theme.of(context).textTheme.bodyLarge!
                              .copyWith(
                                fontSize: 15,
                                color: dark
                                    ? const Color.fromARGB(255, 132, 131, 131)
                                    : AppColors.darkerGrey,
                              ),
                        ),
                      ],
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
