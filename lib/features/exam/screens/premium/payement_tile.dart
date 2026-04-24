import 'package:flutter/material.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

Widget paymentTile({
  required String title,
  required String subtitle,
  required IconData icon,
  bool selected = false,
  required BuildContext context,
  VoidCallback? onTap,
  required bool isFeatured,
}) {
  final dark = AppHelperFuntions.isDark(context);
  return GestureDetector(
    onTap: onTap,
    child: Stack(
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: dark ? AppColors.black : AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? Colors.green
                  : dark
                  ? AppColors.darkerGrey
                  : Colors.grey.shade300,
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: dark
                    ? Colors.grey.withValues(alpha: 0.3)
                    : Colors.grey.shade200,
                child: Icon(icon, color: Colors.teal),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: selected ? Colors.green : Colors.grey,
              ),
            ],
          ),
        ),

       if(isFeatured) Positioned(
          top: 5,
          right: 30,
          child: Text(
            "RECOMMENDED",
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ),
      ],
    ),
  );
}
