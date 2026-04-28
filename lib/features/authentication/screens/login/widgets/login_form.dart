import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matricmate/common/widgets/loaders/circular_loading.dart';
import 'package:matricmate/features/authentication/controllers/login/login_controller.dart';
import 'package:matricmate/routes/app_routes.dart';
import 'package:matricmate/utils/constants/app_strings.dart';
import 'package:matricmate/utils/constants/sizes.dart';
import 'package:matricmate/utils/validators/validators.dart';

class LoginForm extends GetView<LoginController> {
  const LoginForm({super.key});

  @override
  Widget build(BuildContext context) {
    return Form(
      key: controller.loginFormkey,
      child: Column(
        children: [
          TextFormField(
            controller: controller.email,
            onTapOutside: (e) => FocusScope.of(context).unfocus(),
            validator: (value) => AppValidator.validateEmail(value),
            decoration: InputDecoration(
              labelText: AppTextStrings.email,
              prefixIcon: Icon(Icons.email),
            ),
          ),
          const SizedBox(height: AppSizes.defaultSpace),
          Obx(
            () => TextFormField(
              onTapOutside: (e) => FocusScope.of(context).unfocus(),
              obscureText: controller.hidePassword.value,
              controller: controller.password,
              decoration: InputDecoration(
                labelText: AppTextStrings.password,
                prefixIcon: Icon(Icons.lock),
                suffixIcon: IconButton(
                  onPressed: () => controller.hidePassword.value =
                      !controller.hidePassword.value,
                  icon: controller.hidePassword.value
                      ? Icon(Icons.visibility_off)
                      : Icon(Icons.visibility),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSizes.defaultSpace / 2),
          Row(
            children: [
              Obx(
                () => Checkbox(
                  value: controller.rememberMe.value,
                  onChanged: (val) => controller.rememberMe.value = val!,
                ),
              ),
              const Text(AppTextStrings.rememberMe),
            ],
          ),
          TextButton(
            onPressed: () => Get.toNamed(Routes.forgetPassword),
            child: const Text(AppTextStrings.forgetPassword),
          ),
          const SizedBox(height: AppSizes.spaceBtwSections),

          Obx(
            () => SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: controller.isLogging.value
                    ? null
                    : () => controller.emailAndPasswordLogin(),
                child: controller.isLogging.value
                    ? AppCircularBottonLoading()
                    : Text(AppTextStrings.signIn),
              ),
            ),
          ),

          const SizedBox(height: AppSizes.spaceBtwSections),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Get.offNamed(Routes.signup),
              child: Text(AppTextStrings.createAccount),
            ),
          ),

          const SizedBox(height: AppSizes.spaceBtwSections),
        ],
      ),
    );
  }
}
