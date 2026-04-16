import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:matricmate/data/repositories/authentication/authentication_repository.dart';
import 'package:matricmate/utils/helpers/toast_helper.dart';
import 'package:matricmate/utils/network_manager/network_manager.dart';


class LoginController extends GetxController {
  static LoginController get instance => Get.find();
  final _localStroage = GetStorage();

  final rememberMe = false.obs;
  final hidePassword = true.obs;
  final email = TextEditingController();
  final password = TextEditingController();

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

      // Network check
      final isConnected = await NetworkManager.instance.isConnected();
      if (!isConnected) {
      
        return;
      }

      await AuthenticationRepository.instance.loginUsingEmailAndPassword(
        email.value.text.trim(),
        password.value.text.trim(),
      );

      AuthenticationRepository.instance.screenRedirect();
    } catch (e) {
      ToastHelper.error( "Error",  e.toString());
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
