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
            : Colors.grey.shade300,
        borderRadius: BorderRadius.circular(30),
      ),
      // Obx here so the highlighted pill re-renders when languageSelected changes
      child: Obx(() {
        final selected = controller.languageSelected.value;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildItem(
              label: 'En',
              isSelected: selected == 'EN',
              dark: dark,
              onTap: () => controller.languageSelected.value = 'EN',
            ),
            _buildItem(
              label: 'አማ',
              isSelected: selected == 'AM',
              dark: dark,
              onTap: () => controller.languageSelected.value = 'AM',
            ),
          ],
        );
      }),
    );
  }

  Widget _buildItem({
    required String label,
    required bool isSelected,
    required bool dark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? dark
                    ? const Color.fromARGB(255, 44, 44, 44)
                    : Colors.grey.shade100
              : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isSelected
                ? Colors.teal
                : dark
                ? Colors.white70
                : Colors.black54,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
