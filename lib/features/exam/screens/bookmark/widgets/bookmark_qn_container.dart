import 'package:flutter/material.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';
import 'package:get/get_state_manager/src/simple/get_view.dart';
import 'package:matricmate/common/widgets/appbar/appbar.dart';
import 'package:matricmate/features/exam/controllers/bookmark_controller.dart';
import 'package:matricmate/features/exam/models/question_model.dart';
import 'package:matricmate/features/exam/screens/question/widgets/choice_button.dart';
import 'package:matricmate/features/exam/screens/question/widgets/image_section.dart';
import 'package:matricmate/features/exam/screens/question/widgets/question_section.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/constants/sizes.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

class BookmarkedQnContainer extends GetView<BookmarkController> {
  const BookmarkedQnContainer({super.key, required this.qn});
  final QuestionModel qn;

  @override
  Widget build(BuildContext context) {
    final dark = AppHelperFuntions.isDark(context);
    return Scaffold(
      appBar: Appbar(
        showBackArrow: true,
        title: Text(
          "Review Answers",
          style: Theme.of(
            context,
          ).textTheme.headlineSmall!.apply(color: AppColors.white),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppSizes.defaultSpace / 2),
        child: Container(
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
              // qn txt
              QuestionSection(
                qnNumber: qn.questionOrder,
                examQn: qn.questionText,
              ),
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
                  selectedIndex: qn.correctOptionIndex,
                  optionTxt: option,
                  index: index,
                  questionId: qn.id,
                  correctIndex: qn.correctOptionIndex,
                );
              }),
              const SizedBox(height: AppSizes.spaceBtwItems),

              // Explanation button
              Obx(() {
                final expanded = controller.isQnExpanded.value;
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
                              onPressed: () => controller.isQnExpanded.value =
                                  !controller.isQnExpanded.value,
                              child: Row(
                                mainAxisAlignment: !expanded
                                    ? MainAxisAlignment.spaceBetween
                                    : MainAxisAlignment.start,
                                children: [
                                  Text(
                                    "Why this is correct?",
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyLarge!
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
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium!
                                        .copyWith(color: AppColors.primary),
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: 'AM',
                                  child: Text(
                                    "AM",
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium!
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
              }),
            ],
          ),
        ),
      ),
    );
  }
}
