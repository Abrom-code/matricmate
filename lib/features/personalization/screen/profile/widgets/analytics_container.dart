import 'package:flutter/material.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/constants/sizes.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

class AnalyticsContainer extends StatelessWidget {
  const AnalyticsContainer({
    super.key,
    required this.value,
    required this.title,
  });
  final int value;
  final String title;

  @override
  Widget build(BuildContext context) {
    final dark = AppHelperFunctions.isDark(context);
    return Container(
      decoration: BoxDecoration(
        color: !dark ? AppColors.light : AppColors.black,
        borderRadius: BorderRadius.circular(AppSizes.md),
        border: BoxBorder.fromLTRB(
          left: const BorderSide(color: AppColors.primary, width: 4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            spreadRadius: -2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.task_alt_outlined, color: Colors.green, size: 28),
                  const SizedBox(height: 8),
                  Text(
                    '$value',
                    style: TextStyle(
                      color: dark ? AppColors.white : AppColors.black,
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 12,
                      letterSpacing: 1,
                      color: AppColors.darkGrey,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
