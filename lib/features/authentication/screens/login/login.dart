import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matricmate/features/authentication/controllers/login/login_controller.dart';
import 'package:matricmate/features/authentication/screens/login/widgets/login_form.dart';
import 'package:matricmate/features/authentication/screens/login/widgets/login_header.dart';
import 'package:matricmate/utils/constants/sizes.dart';

class LoginScreen extends GetView<LoginController> {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(AppSizes.defaultSpace),
          child: Column(
            children: [
              AppDetail(),
              SizedBox(height: AppSizes.spaceBtwSections),
              LoginForm(),
            ],
          ),
        ),
      ),
    );
  }
}
