import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:matricmate/data/repositories/authentication/authentication_repository.dart';
import 'package:matricmate/data/services/device_service.dart';
import 'package:matricmate/data/services/session_service.dart';
import 'package:matricmate/features/authentication/controllers/authentication_controller.dart';
import 'package:matricmate/features/authentication/screens/login/login.dart';
import 'package:matricmate/utils/exceptions/app_failure_model.dart';
import 'package:matricmate/utils/helpers/toast_helper.dart';
import 'package:matricmate/utils/network_manager/network_manager.dart';

class LoginController extends GetxController {
  static LoginController get instance => Get.find();
  final authRepo = Get.find<AuthenticationRepository>();
  final authController = Get.find<AuthenticationController>();

  final _localStroage = GetStorage();

  final rememberMe = false.obs;
  final hidePassword = true.obs;
  final email = TextEditingController();
  final password = TextEditingController();
  final RxBool isLoaging = false.obs;

  GlobalKey<FormState> loginFormkey = GlobalKey<FormState>();

  @override
  void onInit() {
    loadCredentials();
    super.onInit();
  }

  Future<void> emailAndPasswordLogin() async {
    try {
      if (!loginFormkey.currentState!.validate()) return;

      if (rememberMe.value) {
        _localStroage.writeIfNull("userLoginCredentials", [
          email.value,
          password.value,
        ]);
      } else {
        _localStroage.remove("userLoginCredentials");
      }

      // loading
      isLoaging.value = true;

      // Network check
      final isConnectd = await NetworkManager.instance.hasRealInternet();
      if (!isConnectd) {
        ToastHelper.warning(
          "No Internet!",
          "Please turn on mobile data or connect to WIFI!",
        );
        return;
      }

      await authRepo.loginUsingEmailAndPassword(
        email.value.text.trim(),
        password.value.text.trim(),
      );

      //  Get UID
      final uid = authRepo.currentUser!.uid;

      //  Get device ID
      final deviceId = await DeviceService.getDeviceId();

      //  Validate session
      final isAllowed = await SessionService().validateSession(uid, deviceId);

      if (!isAllowed) {
        await FirebaseAuth.instance.signOut();
        Get.off(() => LoginScreen());
        return;
      }

      //  Proceed if allowed
      authController.screenRedirect();
    } catch (e) {
      if (e is AppFailure) {
        ToastHelper.error(e.title, e.message);
      } else {
        ToastHelper.error("Unexpected Error", e.toString());
      }
    } finally {
      isLoaging.value = false;
    }
  }

  void loadCredentials() {
    final savedCredentials = _localStroage.read("userLoginCredentials");
    if (savedCredentials != null) {
      email.value = savedCredentials[0];
      password.value = savedCredentials[1];
      rememberMe.value = true;
    }
  }
}
