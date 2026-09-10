import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matricmate/routes/app_routes.dart';
import 'package:matricmate/data/repositories/authentication/authentication_repository.dart';
import 'package:matricmate/data/repositories/user/user_repository.dart';
import 'package:matricmate/data/services/device_service.dart';
import 'package:matricmate/data/services/session_service.dart';
import 'package:matricmate/features/authentication/controllers/authentication_controller.dart';
import 'package:matricmate/features/authentication/models/user_model.dart';
import 'package:matricmate/utils/exceptions/exception_handler.dart';
import 'package:matricmate/utils/helpers/toast_helper.dart';
import 'package:matricmate/utils/network_manager/network_manager.dart';

class SignupController extends GetxController {
  static SignupController get instance => Get.find();
  final AuthenticationRepository _authenticationRepository =
      Get.isRegistered<AuthenticationRepository>()
          ? Get.find<AuthenticationRepository>()
          : AuthenticationRepository();

  final hidePassword = true.obs;
  final hideConfirmPassword = true.obs;
  final firstName = TextEditingController();
  final lastName = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  final confirmPassword = TextEditingController();
  final RxString selectedStream = ''.obs;
  final RxBool isSigning = false.obs;

  GlobalKey<FormState> signupFormKey = GlobalKey<FormState>();

  void setStream(String stream) {
    selectedStream.value = stream;
  }

  @override
  void onInit() {
    super.onInit();
  }

  @override
  void onClose() {
    firstName.dispose();
    lastName.dispose();
    email.dispose();
    password.dispose();
    confirmPassword.dispose();
    super.onClose();
  }

  Future<void> signup() async {
    try {
      if (!signupFormKey.currentState!.validate()) return;
      if (password.text.trim() != confirmPassword.text.trim()) {
        ToastHelper.warning('Passwords do not match');
        return;
      }
      if (selectedStream.value.isEmpty) {
        ToastHelper.warning('Please select stream, you can edit later!');
        return;
      }

      // Show loading immediately so the button responds on the exact frame of the tap
      isSigning.value = true;

      final isConnectd = await NetworkManager.instance.isConnected();
      if (!isConnectd) {
        ToastHelper.warning('No Internet!');
        return;
      }

      final fName = firstName.text.trim();
      final lName = lastName.text.trim();
      final emailStr = email.text.trim();
      final streamStr = selectedStream.value.trim();

      // REGISTER USER (Supabase Auth with metadata for trigger)
      final authResponse = await _authenticationRepository
          .registerWithEmailAndPassword(
            emailStr,
            password.text.trim(),
            data: {
              'first_name': fName,
              'last_name': lName,
              'stream': streamStr,
            },
          );

      final user = authResponse.user;
      if (user == null) {
        throw 'Registration failed. Please try again.';
      }

      // When Supabase email confirmation is enabled and auto-confirm is off,
      // session is null until user verifies their email.
      if (authResponse.session == null) {
        ToastHelper.info(
          'Account created! Please check your email to confirm your account before logging in.',
        );
        Get.offNamed(Routes.signIn);
        return;
      }

      final uid = user.id;

      // SAVE USER DATA (trigger creates row, upsert ensures local + remote match)
      final newUser = UserModel(
        id: uid,
        firstName: fName,
        lastName: lName,
        email: emailStr,
        stream: streamStr,
      );

      final userRepository = Get.find<UserRepository>();

      // Parallelize local user record save and device ID retrieval
      final results = await Future.wait([
        userRepository.saveUserRecord(newUser),
        DeviceService.getDeviceId(),
      ]);

      final deviceId = results[1] as String;

      final isAllowed = await SessionService().validateSession(uid, deviceId);

      if (!isAllowed) {
        await _authenticationRepository.logout();
        ToastHelper.error('Failed to register device. Please try again.');
        return;
      }

      // Straight into the app — email verification is optional and lives in
      // Profile → Account Settings.
      AuthenticationController.instance.screenRedirect();
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[SignupController] Registration error: $e\n$st');
      }
      AppExceptionHandler.handleResponse(e);
    } finally {
      isSigning.value = false;
    }
  }
}
