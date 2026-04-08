import 'package:flutter/material.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/constants/sizes.dart';

class AppDropDownField extends StatelessWidget {
  const AppDropDownField({
    super.key,
    required this.items,
    this.initialValue,
    required this.onChanged,
    required this.icon,
  });

  final List<DropdownMenuItem> items;
  final String? initialValue;
  final ValueChanged onChanged;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField(
      iconDisabledColor: AppColors.primary,
      iconEnabledColor: AppColors.primary,
      decoration: InputDecoration(
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.defaultSpace / 2),
          borderSide: BorderSide(
            color: AppColors.primary.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.defaultSpace / 2),
          borderSide: BorderSide(
            color: AppColors.primary.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        prefixIcon: Icon(icon, color: AppColors.primary),
      ),
      initialValue: initialValue,
      items: items,
      onChanged: onChanged,
    );
  }
}
