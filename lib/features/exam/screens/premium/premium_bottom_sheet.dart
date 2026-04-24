import 'package:flutter/material.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:get/instance_manager.dart';
import 'package:matricmate/features/exam/screens/premium/premium.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

class PremiumBottomSheet extends StatelessWidget {
  const PremiumBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = AppHelperFuntions.isDark(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        color: dark ? AppColors.dark : Colors.grey.shade300,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          /// TITLE
          const Text(
            "Unlock Your Full Potential",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 6),

          const Text(
            "Precision tools designed for the modern scholar.",
            style: TextStyle(fontSize: 13, color: Colors.grey),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 20),

          /// FEATURES
          _featureTile(
            Icons.menu_book,
            "Full Mock Exams",
            "Complete simulated testing environments.",
            Colors.blue,
            dark,
          ),
          _featureTile(
            Icons.analytics_outlined,
            "Advanced Analytics",
            "Deep insights into your learning patterns.",
            Colors.green,
            dark,
          ),
          _featureTile(
            Icons.block,
            "Ad-Free Experience",
            "Pure focus, zero distractions during study.",
            Colors.grey,
            dark,
          ),
          _featureTile(
            Icons.block,
            "Ad-Free Experience",
            "Pure focus, zero distractions during study.",
            Colors.grey,
            dark,
          ),

          const SizedBox(height: 20),

          /// BUTTON
          Container(
            width: double.infinity,
            height: 55,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green, AppColors.primary, Color(0xFF3A7BFF)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: () => Get.off(() => PremiumScreen()),
              child: const Text(
                "Premium (250 birr)",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),

          const SizedBox(height: 10),
        ],
      ),
    );
  }

  /// FEATURE TILE
  static Widget _featureTile(
    IconData icon,
    String title,
    String subtitle,
    Color color,
    bool dark,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: dark ? const Color.fromARGB(255, 14, 14, 14) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
