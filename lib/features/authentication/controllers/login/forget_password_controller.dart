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

  late final TextEditingController email;
  final isLoading = false.obs;
  late GlobalKey<FormState> forgetPasswordFormkey;

  @override
  void onInit() {
    email = TextEditingController();
    forgetPasswordFormkey = GlobalKey<FormState>();
    super.onInit();
  }

  Future<void> resetPassword() async {
    try {
      if (!forgetPasswordFormkey.currentState!.validate()) return;
      isLoading.value = true;

      // Network check
      final isConnectd = await NetworkManager.instance.isConnected();
      if (!isConnectd) {
        ToastHelper.warning('Please turn on mobile data or connect to WIFI!');
        return;
      }

      await _authenticationRepository.sendResetPasswordEmail(
        email.value.text.trim(),
      );
      SnackbarHelper.success(
        'Email sent',
        'If you are already registered, please check your inbox!',
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

  @override
  void onClose() {
    email.dispose();
    super.onClose();
  }
}
