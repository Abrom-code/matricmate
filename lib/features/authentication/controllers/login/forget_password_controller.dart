import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matricmate/data/repositories/authentication/authentication_repository.dart';
import 'package:matricmate/routes/app_routes.dart';
import 'package:matricmate/utils/exceptions/exeption_handler.dart';
import 'package:matricmate/utils/helpers/snackbar_helper.dart';
import 'package:matricmate/utils/helpers/toast_helper.dart';
import 'package:matricmate/utils/network_manager/network_manager.dart';

class ForgetPasswordController extends GetxController {
  static ForgetPasswordController get instance => Get.find();
  final AuthenticationRepository _authenticationRepository =
      AuthenticationRepository();

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
        ToastHelper.warning('Please turn on mobile data or connect to WIFI!');
        return;
      }

      await _authenticationRepository.sendResetPasswordEmail(
        email.value.text.trim(),
      );
      SnackbarHelper.success(
        'Email sent',
        'If an you already resgistered, please check your inbox!',
      );

      Get.toNamed(
        Routes.resetPassword,
        arguments: {'email': email.text.trim()},
      );
    } catch (e) {
      AppExceptionHandler.handleResponse(e);
    } finally {
      isLoading.value = false;
    }
  }
}
