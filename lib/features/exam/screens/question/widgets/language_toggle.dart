import 'package:flutter/material.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

class LanguageToggle extends StatelessWidget {
  const LanguageToggle({super.key});

  @override
  Widget build(BuildContext context) {
    final selectedLang = "AM"; // 🔒 hardcoded
    final dark = AppHelperFuntions.isDark(context);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: dark ? AppColors.darkGrey : Colors.grey.shade300, // background
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildItem("English", selectedLang == "EN", context = context),
          _buildItem("አማርኛ", selectedLang == "AM", context = context),
        ],
      ),
    );
  }

  Widget _buildItem(String text, bool selected, BuildContext context) {
    final dark = AppHelperFuntions.isDark(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: selected
            ? dark
                  ? AppColors.darkerGrey
                  : Colors.grey.shade100
            : Colors.transparent,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: selected
              ? Colors.green
              : dark
              ? Colors.white70
              : Colors.black54,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
