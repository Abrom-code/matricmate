import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matricmate/features/authentication/controllers/login/login_controller.dart';
import 'package:matricmate/features/authentication/screens/login/widgets/login_form.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

class LoginScreen extends GetView<LoginController> {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = AppHelperFunctions.isDark(context);

    return Scaffold(
      backgroundColor: dark ? AppColors.dark : const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          // Ambient soft decorative glows for depth
          Positioned(
            top: -50,
            right: -50,
            child: IgnorePointer(
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: dark ? 0.10 : 0.06),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 60,
            left: -60,
            child: IgnorePointer(
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.blueAccent.withValues(alpha: dark ? 0.06 : 0.03),
                ),
              ),
            ),
          ),

          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 32,
                    ),
                    child: const Center(
                      child: LoginForm(),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
