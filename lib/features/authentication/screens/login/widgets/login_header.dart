import 'package:flutter/material.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

class AppDetail extends StatelessWidget {
  const AppDetail({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = AppHelperFunctions.isDark(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Login',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
            color: dark ? AppColors.white : const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: 36,
          height: 3,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }
}
