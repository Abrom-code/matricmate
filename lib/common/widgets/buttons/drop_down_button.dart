import 'package:flutter/material.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/constants/sizes.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

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
    final dark = AppHelperFuntions.isDark(context);
    return DropdownButtonFormField(
      decoration: InputDecoration(
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSizes.defaultSpace / 2),
          borderSide: BorderSide(
            color: dark ? Colors.grey : AppColors.darkGrey,
            width: 2,
          ),
        ),
        prefixIcon: Icon(Icons.book),
      ),
      initialValue: initialValue,
      items: items,
      onChanged: onChanged,
    );
  }
}
