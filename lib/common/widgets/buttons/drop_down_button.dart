import 'package:flutter/material.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/constants/sizes.dart';

class AppDropDownField extends StatelessWidget {
  const AppDropDownField({
    super.key,
    required this.items,
    this.initialValue,
    required this.onChanged,
  });

  final List<DropdownMenuItem> items;
  final String? initialValue;
  final ValueChanged onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField(
      decoration: InputDecoration(
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.defaultSpace / 2),
          borderSide: BorderSide(
            color: AppColors.primary.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        prefixIcon: Icon(Icons.book, color: AppColors.primary),
      ),
      initialValue: initialValue,
      items: items,
      onChanged: onChanged,
    );
  }
}
