import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:matricmate/common/widgets/dialogs/confirm_dialog_box.dart';
import 'package:matricmate/data/repositories/authentication/authentication_repository.dart';
import 'package:matricmate/data/services/device_service.dart';
import 'package:matricmate/data/services/session_service.dart';
import 'package:matricmate/features/authentication/controllers/authentication_controller.dart';
import 'package:matricmate/utils/exceptions/exeption_handler.dart';
import 'package:matricmate/utils/helpers/snackbar_helper.dart';
import 'package:matricmate/utils/helpers/toast_helper.dart';
import 'package:matricmate/utils/network_manager/network_manager.dart';

class LoginController extends GetxController {
  static LoginController get instance => Get.find();
  final authRepo = Get.find<AuthenticationRepository>();
  final authController = Get.find<AuthenticationController>();

  final _localStroage = GetStorage();

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
      final emailText = email.text.trim();
      final passwordText = password.text.trim();

      if (rememberMe.value) {
        _localStroage.writeIfNull("userLoginCredentials", [
          emailText,
          passwordText,
        ]);
      } else {
        _localStroage.remove("userLoginCredentials");
      }

      // Network check
      final isConnectd = await NetworkManager.instance.hasRealInternet();
      if (!isConnectd) {
        ToastHelper.warning("No Internet!");
        return;
      }
      // loading
      isLogging.value = true;
      ;

      await authRepo.loginUsingEmailAndPassword(emailText, passwordText);

      final uid = authRepo.currentUser!.uid;
      final deviceId = await DeviceService.getDeviceId();

      final isAllowed = await SessionService().validateSession(uid, deviceId);

      if (!isAllowed) {
        await FirebaseAuth.instance.signOut();

        trials.value = await SessionService().getTrial(uid);

        AppDialogBoxes.changeDevice(emailText, this, () async {
          isUpdating.value = true;

          if (trials.value <= 0) {
            SnackbarHelper.error(
              "Limit reached",
              "You cannot change device anymore.",
            );
            isUpdating.value = false;
            return;
          }

          await SessionService().updateDevice(uid, deviceId, trials.value - 1);

          await authRepo.loginUsingEmailAndPassword(emailText, passwordText);

          Get.back();
          authController.screenRedirect();

          isUpdating.value = false;
        });

        return;
      }

      authController.screenRedirect();
    } catch (e) {
      AppExceptionHandler.handleResponse(e);
    } finally {
      isLogging.value = false;
    }
  }

  void loadCredentials() {
    final savedCredentials = _localStroage.read("userLoginCredentials");
    if (savedCredentials != null) {
      email.text = savedCredentials[0];
      password.text = savedCredentials[1];
      rememberMe.value = true;
    }
  }
}
