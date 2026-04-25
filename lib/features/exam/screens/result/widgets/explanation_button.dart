import 'package:flutter/material.dart';
import 'package:matricmate/features/exam/controllers/review_controller.dart';
import 'package:matricmate/features/exam/models/question_model.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/constants/sizes.dart' show AppSizes;

class ExplanationButton extends StatelessWidget {
  const ExplanationButton({
    super.key,
    required this.expanded,
    required this.dark,
    required this.controller,
    required this.qn,
  });

  final bool expanded;
  final bool dark;
  final ReviewController controller;
  final QuestionModel qn;

  @override
  Widget build(BuildContext context) {
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
        color: dark
            ? const Color.fromARGB(255, 10, 10, 10)
            : AppColors.white,
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
                  onPressed: () => controller.toggle(qn.id),
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
                  value: controller.languageSelected.value,
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
                            ? AppColors.grey
                            : AppColors.darkerGrey,
                      ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
