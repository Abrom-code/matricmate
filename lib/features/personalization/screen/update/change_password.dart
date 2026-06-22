import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:matricmate/common/widgets/appbar/appbar.dart';
import 'package:matricmate/features/personalization/controller/change_password_controller.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/constants/sizes.dart';
import 'package:matricmate/utils/validators/validators.dart';

class ChangePassword extends GetView<ChangePasswordController> {
  const ChangePassword({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const Appbar(
        title: Text(
          'Change Password',
          style: TextStyle(color: AppColors.white),
        ),
        showBackArrow: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.defaultSpace),
          child: Form(
            key: controller.changePasswordKey,
            child: Column(
              children: [
                const SizedBox(height: AppSizes.spaceBtwItems),

                Obx(
                  () => TextFormField(
                    controller: controller.oldPassword,
                    obscureText: controller.hideOldPassword.value,
                    validator: (val) =>
                        AppValidator.validateEmptyText('Current Password', val),
                    decoration: InputDecoration(
                      labelText: 'Current Password',
                      prefixIcon: const Icon(Iconsax.lock_circle_copy),
                      suffixIcon: IconButton(
                        onPressed: () => controller.hideOldPassword.value =
                            !controller.hideOldPassword.value,
                        icon: Icon(
                          controller.hideOldPassword.value
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: AppSizes.spaceBtwItems),

                Obx(
                  () => TextFormField(
                    controller: controller.newPassword,
                    obscureText: controller.hideNewPassword.value,
                    validator: (val) => AppValidator.validatePassword(val),
                    decoration: InputDecoration(
                      labelText: 'New Password',
                      prefixIcon: const Icon(Iconsax.lock_circle),
                      suffixIcon: IconButton(
                        onPressed: () => controller.hideNewPassword.value =
                            !controller.hideNewPassword.value,
                        icon: Icon(
                          controller.hideNewPassword.value
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: AppSizes.spaceBtwSections),

                Obx(
                  () => SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: controller.isUpdating.value
                          ? null
                          : () => controller.changePassword(),
                      child: controller.isUpdating.value
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Update Password'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
