import 'package:flutter/material.dart';
import 'package:matricmate/features/exam/screens/question/widgets/choice_button.dart';
import 'package:matricmate/features/exam/screens/question/widgets/explanation_box.dart';
import 'package:matricmate/features/exam/screens/question/widgets/image_section.dart';
import 'package:matricmate/features/exam/screens/question/widgets/question_progress_indicator.dart';
import 'package:matricmate/features/exam/screens/question/widgets/question_section.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/constants/sizes.dart';

class NormarQuesionsSection extends StatelessWidget {
  const NormarQuesionsSection({super.key, required this.examQn});

  final int examQn;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        QuestionProgressIndicator(),
        const SizedBox(height: AppSizes.spaceBtwItems),

        // Quesition
        QuestionSection(examQn: examQn),
        const SizedBox(height: AppSizes.spaceBtwItems),

        // If there is Image
        ImageSection(),
        const SizedBox(height: AppSizes.spaceBtwItems),

        // options
        ChoiceButton(),

        ChoiceButton(),

        ChoiceButton(),

        ChoiceButton(),
        const SizedBox(height: AppSizes.spaceBtwItems),
        // explanations
        // opne/colos
        TextButton(
          onPressed: () {},
          child: Row(
            children: [
              Icon(Icons.keyboard_arrow_up, color: AppColors.primary, size: 24),
              Text(
                "Explanation",
                style: Theme.of(context).textTheme.titleMedium!.apply(
                  color: AppColors.primary,
                  fontSizeDelta: 1.4,
                ),
              ),
            ],
          ),
        ),

        ExplanationBox(),

        // Next/check answer button
        const SizedBox(height: AppSizes.spaceBtwItems),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(onPressed: () {}, child: Text("Check Answer")),
        ),
      ],
    );
  }
}
