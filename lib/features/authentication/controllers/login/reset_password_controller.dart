import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matricmate/data/repositories/authentication/authentication_repository.dart';
import 'package:matricmate/features/authentication/controllers/login/login_controller.dart';
import 'package:matricmate/routes/app_routes.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/exceptions/exception_handler.dart';
import 'package:matricmate/utils/helpers/toast_helper.dart';
import 'package:matricmate/utils/network_manager/network_manager.dart';

enum ResetPasswordState {
  idle,
  updatingPassword,
  success,
  error,
}

class ResetPasswordController extends GetxController {
  static ResetPasswordController get instance => Get.find();

  final AuthenticationRepository _authRepo =
      Get.isRegistered<AuthenticationRepository>()
          ? Get.find<AuthenticationRepository>()
          : AuthenticationRepository();

  final email = ''.obs;
  final state = ResetPasswordState.idle.obs;

  late final TextEditingController newPassword;
  late final TextEditingController confirmPassword;
  late final GlobalKey<FormState> resetPasswordFormKey;

  final hideNewPassword = true.obs;
  final hideConfirmPassword = true.obs;
  final isUpdatingPassword = false.obs;

  // Real-time password criteria flags
  final hasMinLength = false.obs;
  final hasSpecialChar = false.obs;
  final passwordsMatch = false.obs;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is Map && args.containsKey('email')) {
      email.value = (args['email'] as String?)?.trim() ?? '';
    }

    newPassword = TextEditingController();
    confirmPassword = TextEditingController();
    resetPasswordFormKey = GlobalKey<FormState>();

    newPassword.addListener(_evaluateCriteria);
    confirmPassword.addListener(_evaluateCriteria);
  }

  void _evaluateCriteria() {
    final pass = newPassword.text;
    final confirm = confirmPassword.text;

    hasMinLength.value = pass.length >= 6;
    hasSpecialChar.value =
        pass.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
    passwordsMatch.value =
        pass.isNotEmpty && confirm.isNotEmpty && pass == confirm;
  }

  /// Submits the new password to Supabase Auth and navigates to Login on success.
  Future<void> submitNewPassword() async {
    if (!resetPasswordFormKey.currentState!.validate()) return;

    if (isUpdatingPassword.value) return;

    try {
      isUpdatingPassword.value = true;
      state.value = ResetPasswordState.updatingPassword;

      final isConnected = await NetworkManager.instance.isConnected();
      if (!isConnected) {
        ToastHelper.warning('Please check your internet connection and try again.');
        state.value = ResetPasswordState.idle;
        return;
      }

      final pass = newPassword.text.trim();
      await _authRepo.updatePassword(pass);

      // Successfully updated; sign out temporary recovery session
      await _authRepo.logout();

      state.value = ResetPasswordState.success;

      _showSuccessDialog();
    } catch (e) {
      state.value = ResetPasswordState.error;
      AppExceptionHandler.handleResponse(e);
      state.value = ResetPasswordState.idle;
    } finally {
      isUpdatingPassword.value = false;
    }
  }

  void _showSuccessDialog() {
    Get.dialog(
      PopScope(
        canPop: false,
        child: Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF10B981),
                    size: 38,
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Password Changed',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                const Text(
                  'Your password has been updated successfully. You can now sign in with your new password.',
                  style: TextStyle(
                    fontSize: 13.5,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _onBackToLoginPressed,
                    child: const Text(
                      'Back to Login',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  void _onBackToLoginPressed() {
    bool foundSignIn = false;
    Get.until((route) {
      if (route.settings.name == Routes.signIn) {
        foundSignIn = true;
        return true;
      }
      if (route.isFirst) {
        return true;
      }
      return false;
    });

    if (foundSignIn) {
      if (Get.isRegistered<LoginController>()) {
        final loginCtrl = Get.find<LoginController>();
        if (email.value.isNotEmpty) {
          loginCtrl.email.text = email.value;
        }
        loginCtrl.password.clear();
      }
    } else {
      Get.offAllNamed(Routes.signIn);
    }
  }

  @override
  void onClose() {
    newPassword.removeListener(_evaluateCriteria);
    confirmPassword.removeListener(_evaluateCriteria);
    newPassword.dispose();
    confirmPassword.dispose();
    super.onClose();
  }
}
