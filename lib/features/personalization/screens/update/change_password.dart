import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:matricmate/common/widgets/appbar/modern_appbar.dart';
import 'package:matricmate/common/widgets/loaders/circular_loading.dart';
import 'package:matricmate/features/personalization/controllers/change_password_controller.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';
import 'package:matricmate/utils/validators/validators.dart';

class ChangePasswordScreen extends GetView<ChangePasswordController> {
  const ChangePasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = AppHelperFunctions.isDark(context);

    return Scaffold(
      backgroundColor: dark ? AppColors.dark : const Color(0xFFF8FAFC),
      appBar: ModernAppbarWithBuilder(
        title: 'Change Password',
        showBackArrow: true,
        subtitleBuilder: (_) => const Text(
          'Security settings',
          style: TextStyle(
            color: Color(0xFFD1FAE5),
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          MediaQuery.paddingOf(context).bottom + 40,
        ),
        child: Form(
          key: controller.changePasswordKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Section Title ────────────────────────────────
              Text(
                'SECURITY & CREDENTIALS',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                  color: dark ? AppColors.darkGrey : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 10),

              // ── Password Inputs Card ─────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: dark ? AppColors.darkCard : AppColors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: dark
                        ? AppColors.darkBorder
                        : const Color(0xFFE2E8F0),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: dark ? 0.2 : 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Current Password
                    Obx(
                      () => TextFormField(
                        controller: controller.oldPassword,
                        obscureText: controller.hideOldPassword.value,
                        style: TextStyle(
                          color: dark
                              ? AppColors.white
                              : const Color(0xFF0F172A),
                          fontSize: 14.5,
                          fontWeight: FontWeight.w500,
                        ),
                        validator: (val) => AppValidator.validateEmptyText(
                            'Current Password', val),
                        onTapOutside: (_) => FocusScope.of(context).unfocus(),
                        decoration: InputDecoration(
                          labelText: 'Current Password',
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
                          suffixIcon: IconButton(
                            onPressed: () => controller.hideOldPassword.value =
                                !controller.hideOldPassword.value,
                            icon: Icon(
                              controller.hideOldPassword.value
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              size: 19,
                              color: dark
                                  ? AppColors.darkInputLabel
                                  : AppColors.lightInputLabel,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // New Password
                    Obx(
                      () => TextFormField(
                        controller: controller.newPassword,
                        obscureText: controller.hideNewPassword.value,
                        style: TextStyle(
                          color: dark
                              ? AppColors.white
                              : const Color(0xFF0F172A),
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
                            Iconsax.lock_1_copy,
                            size: 18,
                            color: dark
                                ? AppColors.darkInputLabel
                                : AppColors.lightInputLabel,
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
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── Password Requirement Info ────────────────────
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: dark
                      ? AppColors.darkSurface
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: dark
                        ? AppColors.darkInputBorder
                        : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Iconsax.info_circle_copy,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Password should be at least 6 characters long and include numbers or symbols.',
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.35,
                          color: dark
                              ? AppColors.darkInputLabel
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── Save Button ──────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 48,
                child: Obx(
                  () => ElevatedButton(
                    onPressed: controller.isUpdating.value
                        ? null
                        : () => controller.changePassword(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: controller.isUpdating.value
                        ? const AppCircularButtonLoading(color: Colors.white)
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_rounded, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Update Password',
                                style: TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
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
}
