import 'package:flutter/material.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';
import 'package:matricmate/utils/validators/validators.dart';

class LinkInputFiled extends StatelessWidget {
  const LinkInputFiled({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = AppHelperFuntions.isDark(context);

    return TextFormField(
      onTapOutside: (_) => FocusScope.of(context).unfocus(),
      style: const TextStyle(fontSize: 14),
      validator: (value) => AppValidator.isValidUrl(value!),
      decoration: InputDecoration(
        hintText: "https://cbe.com:299/verify....",
        hintStyle: Theme.of(context).textTheme.labelMedium,
        // Prefix icon
        prefixIcon: const Icon(Icons.link, color: Colors.teal),

        // Filled background
        filled: true,
        fillColor: isDark ? AppColors.dark : Colors.grey.shade100,

        // Content spacing
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),

        // Default border
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),

        // Enabled border
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? AppColors.darkerGrey : Colors.grey.shade300,
          ),
        ),

        // Focused border
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.teal, width: 1.5),
        ),

        // Optional label
        labelText: "Payment Link",
        labelStyle: const TextStyle(color: Colors.teal),
      ),
    );
  }
}
