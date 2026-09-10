import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:matricmate/common/widgets/loaders/circular_loading.dart';
import 'package:matricmate/features/authentication/controllers/login/reset_password_controller.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';
import 'package:matricmate/utils/validators/validators.dart';

class ResetPasswordScreen extends GetView<ResetPasswordController> {
  const ResetPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = AppHelperFunctions.isDark(context);

    return Scaffold(
      backgroundColor: dark ? AppColors.dark : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 19,
            color: dark ? AppColors.white : const Color(0xFF0F172A),
          ),
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          20,
          8,
          20,
          MediaQuery.paddingOf(context).bottom + 24,
        ),
        child: Form(
          key: controller.resetPasswordFormKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon Badge
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Iconsax.key_copy,
                  color: Color(0xFF10B981),
                  size: 26,
                ),
              ),
              const SizedBox(height: 18),

              // Title
              Text(
                'Set New Password',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                  color: dark ? AppColors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),

              // Subtitle
              Text(
                'Your identity has been verified. Create a strong, new password for your account.',
                style: TextStyle(
                  fontSize: 13.5,
                  height: 1.45,
                  color: dark ? AppColors.darkGrey : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),

              // Inputs Card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: dark ? AppColors.darkCard : AppColors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: dark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: dark ? 0.2 : 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // New Password
                    Obx(
                      () => TextFormField(
                        controller: controller.newPassword,
                        obscureText: controller.hideNewPassword.value,
                        style: TextStyle(
                          color: dark ? AppColors.white : const Color(0xFF0F172A),
                          fontSize: 14.5,
                          fontWeight: FontWeight.w500,
                        ),
                        validator: (val) => AppValidator.validatePassword(val),
                        onTapOutside: (_) => FocusScope.of(context).unfocus(),
                        decoration: InputDecoration(
                          labelText: 'New Password',
                          labelStyle: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                            color: dark
                                ? AppColors.darkInputLabel
                                : AppColors.lightInputLabel,
                          ),
                          floatingLabelStyle: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                          hintStyle: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w400,
                            color: dark
                                ? AppColors.darkInputHint
                                : AppColors.lightInputHint,
                          ),
                          prefixIcon: Icon(
                            Iconsax.lock_copy,
                            size: 18,
                            color: dark
                                ? AppColors.darkInputLabel
                                : AppColors.lightInputLabel,
                          ),
                          suffixIcon: IconButton(
                            onPressed: () => controller.hideNewPassword.value =
                                !controller.hideNewPassword.value,
                            icon: Icon(
                              controller.hideNewPassword.value
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              size: 19,
                              color: dark
                                  ? AppColors.darkInputLabel
                                  : AppColors.lightInputLabel,
                            ),
                          ),
                          filled: true,
                          fillColor: dark
                              ? AppColors.darkInputFill
                              : AppColors.lightInputFill,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: dark
                                  ? AppColors.darkInputBorder
                                  : AppColors.lightInputBorder,
                              width: 1.2,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: dark
                                  ? AppColors.darkInputBorder
                                  : AppColors.lightInputBorder,
                              width: 1.2,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.primary,
                              width: 1.6,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Confirm Password
                    Obx(
                      () => TextFormField(
                        controller: controller.confirmPassword,
                        obscureText: controller.hideConfirmPassword.value,
                        style: TextStyle(
                          color: dark ? AppColors.white : const Color(0xFF0F172A),
                          fontSize: 14.5,
                          fontWeight: FontWeight.w500,
                        ),
                        validator: (val) => AppValidator.validateConfirmPassword(
                          val,
                          controller.newPassword.text,
                        ),
                        onTapOutside: (_) => FocusScope.of(context).unfocus(),
                        decoration: InputDecoration(
                          labelText: 'Confirm Password',
                          labelStyle: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                            color: dark
                                ? AppColors.darkInputLabel
                                : AppColors.lightInputLabel,
                          ),
                          floatingLabelStyle: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                          hintStyle: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w400,
                            color: dark
                                ? AppColors.darkInputHint
                                : AppColors.lightInputHint,
                          ),
                          prefixIcon: Icon(
                            Iconsax.lock_1_copy,
                            size: 18,
                            color: dark
                                ? AppColors.darkInputLabel
                                : AppColors.lightInputLabel,
                          ),
                          suffixIcon: IconButton(
                            onPressed: () => controller.hideConfirmPassword.value =
                                !controller.hideConfirmPassword.value,
                            icon: Icon(
                              controller.hideConfirmPassword.value
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              size: 19,
                              color: dark
                                  ? AppColors.darkInputLabel
                                  : AppColors.lightInputLabel,
                            ),
                          ),
                          filled: true,
                          fillColor: dark
                              ? AppColors.darkInputFill
                              : AppColors.lightInputFill,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: dark
                                  ? AppColors.darkInputBorder
                                  : AppColors.lightInputBorder,
                              width: 1.2,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: dark
                                  ? AppColors.darkInputBorder
                                  : AppColors.lightInputBorder,
                              width: 1.2,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: AppColors.primary,
                              width: 1.6,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Password Rules Checklist
                    _buildRequirementRow(
                      controller.hasMinLength,
                      'At least 6 characters long',
                      dark,
                    ),
                    const SizedBox(height: 8),
                    _buildRequirementRow(
                      controller.hasSpecialChar,
                      'Contains at least one special character (!@#\$%^&*)',
                      dark,
                    ),
                    const SizedBox(height: 8),
                    _buildRequirementRow(
                      controller.passwordsMatch,
                      'Passwords match',
                      dark,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: Obx(
                  () => ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: controller.isUpdatingPassword.value
                        ? null
                        : () => controller.submitNewPassword(),
                    child: controller.isUpdatingPassword.value
                        ? const AppCircularButtonLoading(color: Colors.white)
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Update Password',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(Icons.check_rounded, size: 20),
                            ],
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRequirementRow(RxBool condition, String text, bool dark) {
    return Obx(() {
      final isMet = condition.value;
      final activeColor = const Color(0xFF10B981);
      final inactiveColor = dark ? AppColors.darkGrey : AppColors.textSecondary;

      return Row(
        children: [
          Icon(
            isMet ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
            size: 16,
            color: isMet ? activeColor : inactiveColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isMet ? FontWeight.w600 : FontWeight.w400,
                color: isMet
                    ? (dark ? Colors.white : const Color(0xFF0F172A))
                    : inactiveColor,
              ),
            ),
          ),
        ],
      );
    });
  }
}
