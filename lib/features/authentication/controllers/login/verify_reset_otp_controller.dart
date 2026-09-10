import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matricmate/data/repositories/authentication/authentication_repository.dart';
import 'package:matricmate/routes/app_routes.dart';
import 'package:matricmate/utils/exceptions/exception_handler.dart';
import 'package:matricmate/utils/helpers/snackbar_helper.dart';
import 'package:matricmate/utils/helpers/toast_helper.dart';
import 'package:matricmate/utils/network_manager/network_manager.dart';

enum OtpRecoveryState {
  idle,
  sendingOtp,
  otpSent,
  verifyingOtp,
  otpVerified,
  error,
}

class VerifyResetOtpController extends GetxController {
  static VerifyResetOtpController get instance => Get.find();

  final AuthenticationRepository _authRepo =
      Get.isRegistered<AuthenticationRepository>()
          ? Get.find<AuthenticationRepository>()
          : AuthenticationRepository();

  final email = ''.obs;
  final otpCode = ''.obs;
  final state = OtpRecoveryState.otpSent.obs;

  final isVerifying = false.obs;
  final isResending = false.obs;
  final resendCooldown = 60.obs;

  Timer? _cooldownTimer;

  // Controllers & FocusNodes for 6 individual OTP cells
  final List<TextEditingController> otpControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> focusNodes = List.generate(6, (_) => FocusNode());

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is Map && args.containsKey('email')) {
      email.value = (args['email'] as String?)?.trim() ?? '';
    }
    _startCooldownTimer();
  }

  /// Formats email into masked form (e.g. j***n@gmail.com) for secure display.
  String get maskedEmail {
    final raw = email.value;
    if (raw.isEmpty || !raw.contains('@')) return raw;

    final parts = raw.split('@');
    final username = parts[0];
    final domain = parts[1];

    if (username.length <= 2) {
      return '${username[0]}***@$domain';
    }
    return '${username[0]}***${username[username.length - 1]}@$domain';
  }

  void _startCooldownTimer() {
    _cooldownTimer?.cancel();
    resendCooldown.value = 60;
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (resendCooldown.value > 0) {
        resendCooldown.value--;
      } else {
        timer.cancel();
      }
    });
  }

  /// Synchronizes the unified OTP code from the 6 individual text controllers.
  void updateOtpFromControllers() {
    final code = otpControllers.map((c) => c.text).join();
    otpCode.value = code;
    if (code.length == 6) {
      // Auto-submit when all 6 digits are typed
      verifyOtp();
    }
  }

  /// Handles paste of a 6-digit string across all cells.
  void handlePastedOtp(String pasted) {
    final cleaned = pasted.replaceAll(RegExp(r'\D'), '');
    if (cleaned.isEmpty) return;

    for (int i = 0; i < 6; i++) {
      if (i < cleaned.length) {
        otpControllers[i].text = cleaned[i];
      } else {
        otpControllers[i].clear();
      }
    }

    final targetIndex = cleaned.length >= 6 ? 5 : cleaned.length;
    focusNodes[targetIndex].requestFocus();
    updateOtpFromControllers();
  }

  /// Verifies the 6-digit OTP code against Supabase Auth.
  Future<void> verifyOtp() async {
    final token = otpCode.value.trim();
    if (token.length != 6) {
      ToastHelper.warning('Please enter all 6 digits of the verification code.');
      return;
    }

    if (isVerifying.value) return;

    try {
      isVerifying.value = true;
      state.value = OtpRecoveryState.verifyingOtp;

      final isConnected = await NetworkManager.instance.isConnected();
      if (!isConnected) {
        ToastHelper.warning('Please check your internet connection and try again.');
        state.value = OtpRecoveryState.otpSent;
        return;
      }

      await _authRepo.verifyPasswordResetOtp(
        email: email.value,
        token: token,
      );

      state.value = OtpRecoveryState.otpVerified;
      SnackbarHelper.success(
        'Code Verified',
        'Verification successful! Please create your new password.',
      );

      // Navigate to Reset Password Screen with email
      Get.toNamed(
        Routes.resetPassword,
        arguments: {'email': email.value},
      );
    } catch (e) {
      state.value = OtpRecoveryState.error;
      AppExceptionHandler.handleResponse(e);
      state.value = OtpRecoveryState.otpSent;
    } finally {
      isVerifying.value = false;
    }
  }

  /// Resends a new 6-digit recovery OTP code via Supabase.
  Future<void> resendOtp() async {
    if (resendCooldown.value > 0 || isResending.value) return;

    try {
      isResending.value = true;
      state.value = OtpRecoveryState.sendingOtp;

      final isConnected = await NetworkManager.instance.isConnected();
      if (!isConnected) {
        ToastHelper.warning('Please check your internet connection and try again.');
        state.value = OtpRecoveryState.otpSent;
        return;
      }

      await _authRepo.sendPasswordResetOtp(email.value);

      state.value = OtpRecoveryState.otpSent;
      _startCooldownTimer();

      // Clear input fields for the fresh code
      for (final controller in otpControllers) {
        controller.clear();
      }
      otpCode.value = '';
      if (focusNodes.isNotEmpty) {
        focusNodes[0].requestFocus();
      }

      ToastHelper.success('A new 6-digit verification code has been sent!');
    } catch (e) {
      state.value = OtpRecoveryState.error;
      AppExceptionHandler.handleResponse(e);
      state.value = OtpRecoveryState.otpSent;
    } finally {
      isResending.value = false;
    }
  }

  @override
  void onClose() {
    _cooldownTimer?.cancel();
    for (final c in otpControllers) {
      c.dispose();
    }
    for (final f in focusNodes) {
      f.dispose();
    }
    super.onClose();
  }
}
