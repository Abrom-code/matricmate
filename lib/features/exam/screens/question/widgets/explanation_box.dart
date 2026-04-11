import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/src/extension_instance.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';
import 'package:matricmate/features/exam/controllers/question_controller.dart';
import 'package:matricmate/features/exam/screens/question/widgets/language_toggle.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

class ExplanationBox extends StatelessWidget {
  const ExplanationBox({
    super.key,
    this.explanationEn = "No English Explanation!",
    this.explanationAm = " No Amharic Explanation!",
  });
  final String explanationEn;
  final String explanationAm;

  @override
  Widget build(BuildContext context) {
    final dark = AppHelperFuntions.isDark(context);
    final controller = Get.find<QuestionController>();

    return Container(
      width: double.infinity,

      decoration: BoxDecoration(
        color: dark
            ? AppColors.darkerGrey.withValues(alpha: 0.5)
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Obx(
        () => Stack(
          children: [
            // Language Toggle (Top Right)
            Positioned(top: 5, right: 5, child: LanguageToggle()),

            // Explanation text
            Padding(
              padding: const EdgeInsets.only(
                top: 50,
                right: 16,
                left: 16,
                bottom: 16,
              ),
              child: Text(
                controller.languageSelected.value == "AM"
                    ? explanationAm
                    : explanationEn,
                textAlign: TextAlign.justify,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
