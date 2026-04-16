import 'package:flutter/material.dart';
import 'package:matricmate/features/authentication/screens/login/widgets/login_form.dart';
import 'package:matricmate/features/authentication/screens/login/widgets/login_header.dart';
import 'package:matricmate/utils/constants/sizes.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(AppSizes.defaultSpace),
          child: Column(
            children: [
              AppDetail(),
              const SizedBox(height: AppSizes.spaceBtwSections),
              LoginForm(),
            ],
          ),
        ),
      ),
    );
  }
}
