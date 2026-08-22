import 'package:flutter/material.dart';
import 'package:matricmate/features/authentication/screens/signup/widgets/signup_form.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = AppHelperFunctions.isDark(context);

    return Scaffold(
      backgroundColor: dark ? AppColors.dark : const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            20,
            12,
            20,
            MediaQuery.paddingOf(context).bottom + 24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 28),

              // Title
              Text(
                'Create Account',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.6,
                  color: dark ? AppColors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 6),

              // Subtitle
              Text(
                'Sign up to access matric exams, study practice, and tracking.',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.45,
                  color: dark ? AppColors.darkGrey : AppColors.textSecondary,
                ),
              ),

              const SizedBox(height: 24),

              const SignupForm(),
            ],
          ),
        ),
      ),
    );
  }
}
