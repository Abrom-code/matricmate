import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:matricmate/common/widgets/dialogs/confirm_dialog_box.dart';
import 'package:matricmate/data/repositories/authentication/authentication_repository.dart';
import 'package:matricmate/data/repositories/user/user_repository.dart';
import 'package:matricmate/data/services/device_service.dart';
import 'package:matricmate/data/services/session_service.dart';
import 'package:matricmate/features/authentication/controllers/authentication_controller.dart';
import 'package:matricmate/features/authentication/models/user_model.dart';
import 'package:matricmate/utils/exceptions/exception_handler.dart';
import 'package:matricmate/utils/helpers/snackbar_helper.dart';
import 'package:matricmate/utils/helpers/toast_helper.dart';
import 'package:matricmate/utils/network_manager/network_manager.dart';

class LoginController extends GetxController {
  static LoginController get instance => Get.find();
  final authRepo = Get.find<AuthenticationRepository>();
  final authController = Get.find<AuthenticationController>();

  final _secureStorage = const FlutterSecureStorage();

  final rememberMe = false.obs;
  final hidePassword = true.obs;
  final isUpdating = false.obs;

  final email = TextEditingController();
  final password = TextEditingController();
  final RxBool isLogging = false.obs;
  final RxInt trials = 3.obs;

  GlobalKey<FormState> loginFormkey = GlobalKey<FormState>();

  @override
  void onInit() {
    loadCredentials();
    super.onInit();
  }

  Future<void> emailAndPasswordLogin() async {
    try {
      if (!loginFormkey.currentState!.validate()) return;

      // Show loading immediately so the button feels responsive.
      isLogging.value = true;

      final emailText = email.text.trim();
      final passwordText = password.text.trim();

      if (rememberMe.value) {
        await _secureStorage.write(key: 'saved_email', value: emailText);
      } else {
        await _secureStorage.delete(key: 'saved_email');
      }
      await _secureStorage.delete(key: 'saved_password');

      // Network check
      final isConnected = await NetworkManager.instance.isConnected();
      if (!isConnected) {
        ToastHelper.warning('No Internet!');
        return;
      }

      await authRepo.loginUsingEmailAndPassword(emailText, passwordText);

      final user = authRepo.currentUser;
      if (user == null) {
        throw 'Authentication failed. Please try again.';
      }
      final uid = user.id;

      // Ensure user profile exists in public.users to satisfy foreign key constraints
      try {
        final userRepo = Get.isRegistered<UserRepository>()
            ? Get.find<UserRepository>()
            : UserRepository();
        final existingProfile = await userRepo.fetchCurrentUserDetails();
        if (existingProfile == null) {
          final metadata = user.userMetadata ?? {};
          final fName = (metadata['first_name'] as String?) ?? '';
          final lName = (metadata['last_name'] as String?) ?? '';
          final streamStr = (metadata['stream'] as String?) ?? 'Natural';
          final fallbackUser = UserModel(
            id: uid,
            firstName: fName,
            lastName: lName,
            email: user.email ?? emailText,
            stream: streamStr,
          );
          await userRepo.saveUserRecord(fallbackUser);
        }
      } catch (profileErr) {
        if (kDebugMode) {
          debugPrint('[LoginController] Profile sync notice: $profileErr');
        }
      }

      final deviceId = await DeviceService.getDeviceId();
      final sessionResult =
          await SessionService().validateSessionDetailed(uid, deviceId);

      if (sessionResult == SessionValidationResult.error) {
        await authRepo.logout();
        SnackbarHelper.error(
          'Session Error',
          'Could not verify your device session. Please check your internet connection and try again.',
        );
        return;
      }

      if (sessionResult == SessionValidationResult.blocked) {
        // Query remaining trials WHILE STILL AUTHENTICATED
        final remainingTrials = await SessionService().getTrial(uid);
        trials.value = remainingTrials >= 0 ? remainingTrials : 0;

        AppDialogBoxes.changeDevice(emailText, this, () async {
          isUpdating.value = true;

          if (trials.value <= 0) {
            SnackbarHelper.error(
              'Limit reached',
              'You cannot change device anymore.',
            );
            await authRepo.logout();
            isUpdating.value = false;
            return;
          }

          final updated = await SessionService().updateDevice(
            uid,
            deviceId,
            trials.value - 1,
          );
          if (!updated) {
            await authRepo.logout();
            isUpdating.value = false;
            return;
          }

          Get.back();
          authController.screenRedirect();
          isUpdating.value = false;
        });

        return;
      }

      authController.screenRedirect();
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[LoginController] Login error: $e\n$st');
      }
      AppExceptionHandler.handleResponse(e);
    } finally {
      isLogging.value = false;
    }
  }

  Future<void> loadCredentials() async {
    final savedEmail = await _secureStorage.read(key: 'saved_email');
    if (savedEmail != null && savedEmail.isNotEmpty) {
      email.text = savedEmail;
      rememberMe.value = true;
    }
  }

  @override
  void onClose() {
    email.dispose();
    password.dispose();
    super.onClose();
  }
}
