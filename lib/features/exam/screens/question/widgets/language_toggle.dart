import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matricmate/features/exam/controllers/question_controller.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

class LanguageToggle extends StatelessWidget {
  const LanguageToggle({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<QuestionController>();
    final dark = AppHelperFunctions.isDark(context);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: dark
            ? const Color.fromARGB(255, 71, 71, 71)
            : Colors.grey.shade300, // background
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildItem(
            'English',
            controller.languageSelected.value == 'EN',
            context = context,
            () => controller.languageSelected.value = 'EN',
          ),
          _buildItem(
            'አማርኛ',
            controller.languageSelected.value == 'AM',
            context = context,
            () => controller.languageSelected.value = 'AM',
          ),
        ],
      ),
    );
  }

  Widget _buildItem(
    String text,
    bool selected,
    BuildContext context,
    VoidCallback onTap,
  ) {
    final dark = AppHelperFunctions.isDark(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color: selected
              ? dark
                    ? const Color.fromARGB(255, 44, 44, 44)
                    : Colors.grey.shade100
              : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: selected
                ? Colors.teal
                : dark
                ? Colors.white70
                : Colors.black54,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
