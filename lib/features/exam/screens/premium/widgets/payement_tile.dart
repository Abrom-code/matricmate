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
  Widget? detail,
  showIcon = true,
}) {
  final dark = AppHelperFunctions.isDark(context);
  return GestureDetector(
    onTap: onTap,
    child: Stack(
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: dark ? AppColors.darkCard : AppColors.white,
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
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: dark
                        ? AppColors.darkSurface
                        : AppColors.grey.withValues(alpha: 0.4),
                    child: Icon(icon, color: AppColors.primary),
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
                          style: const TextStyle(
                            color: AppColors.darkGrey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (showIcon)
                    Icon(
                      selected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                      color: selected ? AppColors.success : AppColors.darkGrey,
                    ),
                ],
              ),
              if (detail != null) detail,
            ],
          ),
        ),

        if (isFeatured)
          Positioned(
            top: 5,
            right: 30,
            child: Text(
              'RECOMMENDED',
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ),
      ],
    ),
  );
}
