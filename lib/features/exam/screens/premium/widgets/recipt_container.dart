import 'package:flutter/material.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

class ReciptContainer extends StatelessWidget {
  const ReciptContainer({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = AppHelperFuntions.isDark(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.teal.withValues(alpha: 0.4),
          width: 1.5,
          style: BorderStyle.solid,
        ),
        color: isDark ? AppColors.dark : Colors.grey.shade100,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon circle
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.teal.shade50,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.cloud_upload_outlined,
              color: Colors.teal,
              size: 28,
            ),
          ),

          const SizedBox(height: 12),

          const Text(
            "Upload Receipt Screenshot",
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),

          const SizedBox(height: 6),

          Text(
            "PNG, JPG OR PDF UP TO 5MB",
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
