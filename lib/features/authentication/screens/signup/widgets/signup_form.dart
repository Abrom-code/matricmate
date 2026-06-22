import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:matricmate/common/widgets/loaders/circular_loading.dart';
import 'package:matricmate/features/authentication/controllers/signup/signup_controller.dart';
import 'package:matricmate/utils/constants/app_strings.dart';
import 'package:matricmate/utils/constants/sizes.dart';
import 'package:matricmate/utils/validators/validators.dart';

class SignupForm extends GetView<SignupController> {
  const SignupForm({super.key});

  @override
  Widget build(BuildContext context) {
    return Form(
      key: controller.signupFormKey,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: controller.firstName,
                  textCapitalization: TextCapitalization.sentences,
                  validator: (val) =>
                      AppValidator.validateEmptyText('First Name', val),
                  onTapOutside: (e) => FocusScope.of(context).unfocus(),
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
                  textCapitalization: TextCapitalization.sentences,
                  validator: (val) =>
                      AppValidator.validateEmptyText('Last Name', val),
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
            enableSuggestions: true,
            validator: (val) => AppValidator.validateEmail(val),
            onTapOutside: (e) => FocusScope.of(context).unfocus(),
            decoration: const InputDecoration(
              labelText: AppTextStrings.email,
              prefixIcon: Icon(Icons.email_outlined),
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
                prefixIcon: const Icon(Iconsax.lock_circle_copy),
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
          DropdownButtonFormField<String>(
            validator: (value) => AppValidator.validateStream(value),
            hint: const Text('Select Stream'),
            items: const [
              DropdownMenuItem(value: 'natural', child: Text('Natural')),
              DropdownMenuItem(value: 'social', child: Text('Social')),
            ],
            onChanged: (stream) {
              if (stream != null) {
                controller.setStream(stream);
              }
            },
          ),

          const SizedBox(height: AppSizes.spaceBtwSections * 2),

          Obx(
            () => SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: controller.isSigning.value
                    ? null
                    : () => controller.signup(),
                child: controller.isSigning.value
                    ? const AppCircularButtonLoading()
                    : const Text(AppTextStrings.createAccount),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
