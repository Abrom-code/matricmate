import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matricmate/common/widgets/buttons/drop_down_button.dart';
import 'package:matricmate/features/authentication/controllers/signup/signup_controller.dart';
import 'package:matricmate/features/authentication/screens/signup/widgets/term_and_conditions.dart';
import 'package:matricmate/utils/constants/app_strings.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/constants/sizes.dart';
import 'package:matricmate/utils/validators/validators.dart';

class SignupForm extends StatelessWidget {
  const SignupForm({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SignupController());
    return Form(
      key: controller.signupFormKey,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  validator: (val) =>
                      AppValidator.validateEmptyText("First Name", val),
                  onTapOutside: (e) => FocusScope.of(context).unfocus(),
                  controller: controller.firstName,
                  expands: false,
                  decoration: const InputDecoration(
                    labelText: AppTextStrings.firstName,
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
              ),

              const SizedBox(width: AppSizes.spaceBtwInputFields),

              Expanded(
                child: TextFormField(
                  controller: controller.lastName,
                  validator: (val) =>
                      AppValidator.validateEmptyText("Last Name", val),
                  onTapOutside: (e) => FocusScope.of(context).unfocus(),
                  expands: false,
                  decoration: const InputDecoration(
                    labelText: AppTextStrings.lastName,
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSizes.spaceBtwInputFields),

          const SizedBox(height: AppSizes.spaceBtwInputFields),
          // Email
          TextFormField(
            controller: controller.email,
            validator: (val) => AppValidator.validateEmail(val),
            onTapOutside: (e) => FocusScope.of(context).unfocus(),
            decoration: const InputDecoration(
              labelText: AppTextStrings.email,
              prefixIcon: Icon(Icons.email),
            ),
          ),

          const SizedBox(height: AppSizes.spaceBtwInputFields),

          // Password
          Obx(
            () => TextFormField(
              controller: controller.password,
              validator: (val) => AppValidator.validatePassword(val),
              onTapOutside: (e) => FocusScope.of(context).unfocus(),
              obscureText: controller.hidePassword.value,
              decoration: InputDecoration(
                labelText: AppTextStrings.password,
                prefixIcon: Icon(Icons.lock),
                suffixIcon: IconButton(
                  onPressed: () => controller.hidePassword.value =
                      !controller.hidePassword.value,
                  icon: Icon(
                    controller.hidePassword.value == true
                        ? Icons.visibility_off
                        : Icons.visibility,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: AppSizes.spaceBtwInputFields),

          // stream
          DropdownButtonFormField(
            items: [
              DropdownMenuItem(value: "natural", child: Text("Natural")),
              DropdownMenuItem(value: "social", child: Text("Social")),
            ],
            onChanged: (stream) {},
            initialValue: 'natural',
          ),

          const SizedBox(height: AppSizes.spaceBtwSections),

          TermAndConditions(),

          const SizedBox(height: AppSizes.spaceBtwSections),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => controller.signup(),
              child: Text(AppTextStrings.createAccount),
            ),
          ),
        ],
      ),
    );
  }
}
