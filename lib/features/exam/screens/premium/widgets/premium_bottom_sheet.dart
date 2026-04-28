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
            "Precision tools designed for the modern students.",
            style: TextStyle(fontSize: 13, color: Colors.grey),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 20),

          /// FEATURES
          _featureTile(
            Icons.menu_book,
            "All Chapter Tests",
            "Access every chapter-based test across all subjects.",
            Colors.blue,
            dark,
          ),

          _featureTile(
            Icons.school,
            "All Grade Tests",
            "Practice full syllabus tests for your grade level.",
            Colors.deepPurple,
            dark,
          ),

          _featureTile(
            Icons.emoji_events,
            "All Entrance Exams",
            "Get access to past and model entrance exam papers.",
            Colors.orange,
            dark,
          ),

          _featureTile(
            Icons.analytics_outlined,
            "Full Analytics Dashboard",
            "Track accuracy, progress, weak chapters, and performance insights.",
            Colors.green,
            dark,
          ),

          const SizedBox(height: 20),

          /// BUTTON
          Container(
            width: double.infinity,
            height: 55,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green, AppColors.primary, Colors.green],
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
