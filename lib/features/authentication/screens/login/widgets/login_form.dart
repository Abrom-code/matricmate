import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:matricmate/common/widgets/loaders/circular_loading.dart';
import 'package:matricmate/features/authentication/controllers/login/login_controller.dart';
import 'package:matricmate/routes/app_routes.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';
import 'package:matricmate/utils/validators/validators.dart';

class LoginForm extends GetView<LoginController> {
  const LoginForm({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = AppHelperFunctions.isDark(context);

    return Form(
      key: controller.loginFormkey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Credentials Card ───────────────────────────────────────
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
                // Email Field
                TextFormField(
                  controller: controller.email,
                  keyboardType: TextInputType.emailAddress,
                  style: TextStyle(
                    color: dark ? AppColors.white : const Color(0xFF0F172A),
                    fontSize: 14.5,
                    fontWeight: FontWeight.w500,
                  ),
                  onTapOutside: (_) => FocusScope.of(context).unfocus(),
                  validator: (value) => AppValidator.validateEmail(value),
                  decoration: InputDecoration(
                    labelText: 'Email Address',
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
                      Iconsax.sms_copy,
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
                  ),
                ),

                const SizedBox(height: 16),

                // Password Field
                Obx(
                  () => TextFormField(
                    controller: controller.password,
                    obscureText: controller.hidePassword.value,
                    style: TextStyle(
                      color: dark ? AppColors.white : const Color(0xFF0F172A),
                      fontSize: 14.5,
                      fontWeight: FontWeight.w500,
                    ),
                    onTapOutside: (_) => FocusScope.of(context).unfocus(),
                    validator: (value) =>
                        AppValidator.validateEmptyText('Password', value),
                    decoration: InputDecoration(
                      labelText: 'Password',
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
                        onPressed: () => controller.hidePassword.value =
                            !controller.hidePassword.value,
                        icon: Icon(
                          controller.hidePassword.value
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

                const SizedBox(height: 10),

                // Remember Me & Forgot Password Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Obx(
                          () => SizedBox(
                            width: 24,
                            height: 24,
                            child: Checkbox(
                              value: controller.rememberMe.value,
                              activeColor: AppColors.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5),
                              ),
                              onChanged: (val) =>
                                  controller.rememberMe.value = val ?? false,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Remember me',
                          style: TextStyle(
                            fontSize: 13,
                            color: dark
                                ? AppColors.darkGrey
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: () => Get.toNamed(Routes.forgotPassword),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'Forgot Password?',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 22),

          // ── Sign In Button ─────────────────────────────────────────
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
                onPressed: controller.isLogging.value
                    ? null
                    : () => controller.emailAndPasswordLogin(),
                child: controller.isLogging.value
                    ? const AppCircularButtonLoading(color: Colors.white)
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Sign In',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward_rounded, size: 18),
                        ],
                      ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ── Divider ────────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: Divider(
                  color: dark
                      ? AppColors.darkBorder
                      : const Color(0xFFE2E8F0),
                  thickness: 1,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Text(
                  'or',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: dark ? AppColors.darkGrey : AppColors.textSecondary,
                  ),
                ),
              ),
              Expanded(
                child: Divider(
                  color: dark
                      ? AppColors.darkBorder
                      : const Color(0xFFE2E8F0),
                  thickness: 1,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ── Create Account Outlined Button ─────────────────────────
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: () => Get.offNamed(Routes.signup),
              icon: const Icon(Iconsax.user_add_copy, size: 18),
              label: const Text(
                'Create New Account',
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: dark
                      ? AppColors.darkBorder
                      : const Color(0xFFCBD5E1),
                  width: 1.2,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
