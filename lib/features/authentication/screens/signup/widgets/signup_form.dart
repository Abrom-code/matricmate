import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:matricmate/common/widgets/loaders/circular_loading.dart';
import 'package:matricmate/features/authentication/controllers/signup/signup_controller.dart';
import 'package:matricmate/routes/app_routes.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';
import 'package:matricmate/utils/validators/validators.dart';

class SignupForm extends GetView<SignupController> {
  const SignupForm({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = AppHelperFunctions.isDark(context);

    return Form(
      key: controller.signupFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Personal Info Card ───────────────────────────────────────
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
                // Names Row
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: controller.firstName,
                        textCapitalization: TextCapitalization.sentences,
                        style: TextStyle(
                          color: dark ? AppColors.white : const Color(0xFF0F172A),
                          fontSize: 14.5,
                          fontWeight: FontWeight.w500,
                        ),
                        validator: (val) =>
                            AppValidator.validateEmptyText('First Name', val),
                        onTapOutside: (_) => FocusScope.of(context).unfocus(),
                        decoration: InputDecoration(
                          labelText: 'First Name',
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
                            Iconsax.user_copy,
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
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: controller.lastName,
                        textCapitalization: TextCapitalization.sentences,
                        style: TextStyle(
                          color: dark ? AppColors.white : const Color(0xFF0F172A),
                          fontSize: 14.5,
                          fontWeight: FontWeight.w500,
                        ),
                        validator: (val) =>
                            AppValidator.validateEmptyText('Last Name', val),
                        onTapOutside: (_) => FocusScope.of(context).unfocus(),
                        decoration: InputDecoration(
                          labelText: 'Last Name',
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
                            Iconsax.user_copy,
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
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Email Field
                TextFormField(
                  controller: controller.email,
                  keyboardType: TextInputType.emailAddress,
                  style: TextStyle(
                    color: dark ? AppColors.white : const Color(0xFF0F172A),
                    fontSize: 14.5,
                    fontWeight: FontWeight.w500,
                  ),
                  validator: (val) => AppValidator.validateEmail(val),
                  onTapOutside: (_) => FocusScope.of(context).unfocus(),
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
                    validator: (val) => AppValidator.validatePassword(val),
                    onTapOutside: (_) => FocusScope.of(context).unfocus(),
                    obscureText: controller.hidePassword.value,
                    style: TextStyle(
                      color: dark ? AppColors.white : const Color(0xFF0F172A),
                      fontSize: 14.5,
                      fontWeight: FontWeight.w500,
                    ),
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

                const SizedBox(height: 16),

                // Confirm Password Field
                Obx(
                  () => TextFormField(
                    controller: controller.confirmPassword,
                    validator: (val) => AppValidator.validateConfirmPassword(
                        val, controller.password.text),
                    onTapOutside: (_) => FocusScope.of(context).unfocus(),
                    obscureText: controller.hideConfirmPassword.value,
                    style: TextStyle(
                      color: dark ? AppColors.white : const Color(0xFF0F172A),
                      fontSize: 14.5,
                      fontWeight: FontWeight.w500,
                    ),
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
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Stream Selection Card ──────────────────────────────────
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
                Row(
                  children: [
                    const Icon(
                      Icons.school_rounded,
                      size: 18,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Academic Stream',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: dark
                            ? AppColors.white
                            : const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Select your field of study for customized exam preparation:',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: dark ? AppColors.darkGrey : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 14),
                Obx(
                  () => Row(
                    children: [
                      Expanded(
                        child: _SignupStreamChip(
                          title: 'Natural',
                          subtitle: 'Natural Science',
                          icon: Icons.science_rounded,
                          isSelected:
                              controller.selectedStream.value == 'natural',
                          onTap: () => controller.setStream('natural'),
                          dark: dark,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _SignupStreamChip(
                          title: 'Social',
                          subtitle: 'Social Science',
                          icon: Icons.menu_book_rounded,
                          isSelected:
                              controller.selectedStream.value == 'social',
                          onTap: () => controller.setStream('social'),
                          dark: dark,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── Create Account Button ──────────────────────────────────
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
                onPressed: controller.isSigning.value
                    ? null
                    : () => controller.signup(),
                child: controller.isSigning.value
                    ? const AppCircularButtonLoading(color: Colors.white)
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Create Account',
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

          // ── Switch to Login Footer ─────────────────────────────────
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Already have an account?',
                  style: TextStyle(
                    fontSize: 13.5,
                    color: dark ? AppColors.darkGrey : AppColors.textSecondary,
                  ),
                ),
                TextButton(
                  onPressed: () => Get.offNamed(Routes.signIn),
                  child: const Text(
                    'Sign In',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _SignupStreamChip extends StatelessWidget {
  const _SignupStreamChip({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    required this.dark,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withValues(alpha: dark ? 0.22 : 0.10)
                : (dark ? AppColors.darkInputFill : AppColors.lightInputFill),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? AppColors.primary
                  : (dark ? AppColors.darkInputBorder : AppColors.lightInputBorder),
              width: isSelected ? 1.8 : 1.2,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary
                      : (dark ? AppColors.darkSurface : const Color(0xFFE2E8F0)),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 17,
                  color: isSelected
                      ? Colors.white
                      : (dark ? AppColors.darkInputLabel : AppColors.lightInputLabel),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: isSelected
                            ? AppColors.primary
                            : (dark
                                ? AppColors.white
                                : const Color(0xFF0F172A)),
                      ),
                    ),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                        color: isSelected
                            ? AppColors.primary.withValues(alpha: 0.85)
                            : (dark
                                ? AppColors.darkGrey
                                : AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
