import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matricmate/common/widgets/exam/explanation_box.dart';
import 'package:matricmate/features/exam/controllers/question_controller.dart';

class ExplanationBox extends StatelessWidget {
  const ExplanationBox({
    super.key,
    this.explanationEn = 'No English Explanation!',
    this.explanationAm = 'No Amharic Explanation!',
    this.explanationImageUrl,
  });

  final String explanationEn;
  final String explanationAm;
  final String? explanationImageUrl;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<QuestionController>();

    return Obx(() => AppExplanationBox(
      explanationEn: explanationEn,
      explanationAm: explanationAm,
      explanationImageUrl: explanationImageUrl,
      expanded: controller.isExplanationExpanaded.value,
      onToggle: () => controller.isExplanationExpanaded.value =
          !controller.isExplanationExpanaded.value,
      languageSelected: controller.languageSelected,
      onLanguageChange: (v) => controller.languageSelected.value = v,
    ));
  }
}
