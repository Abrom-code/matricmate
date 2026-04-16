import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matricmate/data/repositories/authentication/authentication_repository.dart';
import 'package:matricmate/features/authentication/screens/password_configration/reset_password.dart';
import 'package:matricmate/utils/helpers/toast_helper.dart';
import 'package:matricmate/utils/network_manager/network_manager.dart';

class ForgetPasswordController extends GetxController {
  static ForgetPasswordController get instance => Get.find();

  final email = TextEditingController();
  final isLoading = false.obs;
  GlobalKey<FormState> forgetPasswordFormkey = GlobalKey<FormState>();

  Future<void> resetPassword() async {
    try {
      if (!forgetPasswordFormkey.currentState!.validate()) return;
      isLoading.value = true;

      // Network check
      final isConnectd = await NetworkManager.instance.hasRealInternet();
      if (!isConnectd) {
        ToastHelper.warning(
          "No Internet!",
          "Please turn on mobile data or connect to WIFI!",
        );
        return;
      }

      await AuthenticationRepository.instance.sendResetPasswordEmail(
        email.value.text.trim(),
      );
      ToastHelper.success("Email sent", "Please check your inbox!");

      Get.to(() => ResetPassword(email: email.text.trim()));
    } catch (e) {
      ToastHelper.error("Error", e.toString());
    } finally {
      isLoading.value = false;
    }
  }
}
