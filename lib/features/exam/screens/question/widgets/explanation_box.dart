import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matricmate/features/exam/controllers/question_controller.dart';
import 'package:matricmate/features/exam/screens/question/widgets/language_toggle.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

class ExplanationBox extends StatelessWidget {
  const ExplanationBox({
    super.key,
    this.explanationEn = 'No English Explanation!',
    this.explanationAm = ' No Amharic Explanation!',
  });
  final String explanationEn;
  final String explanationAm;

  @override
  Widget build(BuildContext context) {
    final dark = AppHelperFunctions.isDark(context);
    final controller = Get.find<QuestionController>();

    return Container(
      width: double.infinity,

      decoration: BoxDecoration(
        color: dark
            ? AppColors.darkerGrey.withValues(alpha: 0.5)
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: BoxBorder.all(color: AppColors.primary.withValues(alpha: .5)),
      ),
      child: Obx(
        () => Stack(
          children: [
            // Language Toggle (Top Right)
            const Positioned(top: 5, right: 10, child: LanguageToggle()),
            Positioned(
              top: 10,
              left: 15,
              child: Text(
                'Explanation',
                style: Theme.of(
                  context,
                ).textTheme.labelSmall!.copyWith(fontSize: 16),
              ),
            ),
            const Divider(height: 78),
            // Explanation text
            Padding(
              padding: const EdgeInsets.only(
                top: 50,
                right: 16,
                left: 16,
                bottom: 16,
              ),
              child: SelectableText(
                controller.languageSelected.value == 'AM'
                    ? explanationAm
                    : explanationEn,
                textAlign: TextAlign.left,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.6,
                  letterSpacing: 0.1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
