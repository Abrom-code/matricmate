import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:matricmate/common/widgets/loaders/circular_loading.dart';
import 'package:matricmate/features/authentication/controllers/login/login_controller.dart';
import 'package:matricmate/features/personalization/utils/profile_actions_helper.dart';
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
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Credentials Card ───────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: dark ? AppColors.darkCard : Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: dark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: dark ? 0.25 : 0.04),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
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
                    hintText: 'student@example.com',
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
                      size: 19,
                      color: dark
                          ? AppColors.darkInputLabel
                          : AppColors.lightInputLabel,
                    ),
                    filled: true,
                    fillColor: dark
                        ? AppColors.darkInputFill
                        : AppColors.lightInputFill,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: dark
                            ? AppColors.darkInputBorder
                            : AppColors.lightInputBorder,
                        width: 1.2,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: dark
                            ? AppColors.darkInputBorder
                            : AppColors.lightInputBorder,
                        width: 1.2,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: AppColors.primary,
                        width: 1.6,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: AppColors.error,
                        width: 1.2,
                      ),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: AppColors.error,
                        width: 1.6,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 18),

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
                      hintText: 'Enter your password',
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
                        size: 19,
                        color: dark
                            ? AppColors.darkInputLabel
                            : AppColors.lightInputLabel,
                      ),
                      filled: true,
                      fillColor: dark
                          ? AppColors.darkInputFill
                          : AppColors.lightInputFill,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: dark
                              ? AppColors.darkInputBorder
                              : AppColors.lightInputBorder,
                          width: 1.2,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: dark
                              ? AppColors.darkInputBorder
                              : AppColors.lightInputBorder,
                          width: 1.2,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: AppColors.primary,
                          width: 1.6,
                        ),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: AppColors.error,
                          width: 1.2,
                        ),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: AppColors.error,
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
                          size: 20,
                          color: dark
                              ? AppColors.darkInputLabel
                              : AppColors.lightInputLabel,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Remember Me & Forgot Password Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InkWell(
                      onTap: () =>
                          controller.rememberMe.value = !controller.rememberMe.value,
                      borderRadius: BorderRadius.circular(6),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                        child: Row(
                          children: [
                            Obx(
                              () => SizedBox(
                                width: 22,
                                height: 22,
                                child: Checkbox(
                                  value: controller.rememberMe.value,
                                  activeColor: AppColors.primary,
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  visualDensity: VisualDensity.compact,
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
                                fontWeight: FontWeight.w500,
                                color: dark
                                    ? AppColors.darkGrey
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
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

          const SizedBox(height: 24),

          // ── Login Button ───────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 52,
            child: Obx(
              () => ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shadowColor: AppColors.primary.withValues(alpha: 0.35),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
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
                            'Login',
                            style: TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward_rounded, size: 19),
                        ],
                      ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ── Switch to Register Footer ──────────────────────────────
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: dark
                    ? Colors.white.withValues(alpha: 0.04)
                    : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: dark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: dark ? 0.15 : 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Don't have an account?",
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                      color: dark ? AppColors.darkGrey : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => Get.offNamed(Routes.signup),
                    borderRadius: BorderRadius.circular(6),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      child: Text(
                        'Register',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ── Support Bot Link ───────────────────────────────────────
          Center(
            child: InkWell(
              onTap: ProfileActionsHelper.openTelegramSupport,
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF38BDF8), Color(0xFF0284C7)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(Icons.send_rounded, size: 10, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Need help? Contact support',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: dark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
