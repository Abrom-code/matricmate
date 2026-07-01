import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matricmate/data/repositories/authentication/authentication_repository.dart';
import 'package:matricmate/utils/exceptions/exeption_handler.dart';
import 'package:matricmate/utils/helpers/snackbar_helper.dart';
import 'package:matricmate/utils/helpers/toast_helper.dart';
import 'package:matricmate/utils/network_manager/network_manager.dart';

class ChangePasswordController extends GetxController {
  static ChangePasswordController get instance => Get.find();

  final AuthenticationRepository _authRepo =
      Get.find<AuthenticationRepository>();

  final hideOldPassword = true.obs;
  final hideNewPassword = true.obs;
  final isUpdating = false.obs;

  late GlobalKey<FormState> changePasswordKey;
  late final TextEditingController oldPassword;
  late final TextEditingController newPassword;

  @override
  void onInit() {
    changePasswordKey = GlobalKey<FormState>();
    oldPassword = TextEditingController();
    newPassword = TextEditingController();
    super.onInit();
  }

  Future<void> changePassword() async {
    try {
      isUpdating.value = true;

      final isConnected = await NetworkManager.instance.isConnected();

      if (!isConnected) {
        ToastHelper.warning('No Internet');
        return;
      }

      if (!changePasswordKey.currentState!.validate()) return;

      final user = _authRepo.currentUser;

      if (user == null || user.email == null) {
        SnackbarHelper.error('Error', 'No authenticated user found.');
        return;
      }

      // 1. Re-auth through repository
      await _authRepo.reAuthenticate(user.email!, oldPassword.text.trim());

      // 2. Update password
      await _authRepo.updateUserPassword(newPassword.text.trim());

      oldPassword.clear();
      newPassword.clear();

      Get.back();

      ToastHelper.success('Your password has been updated.');
    } catch (e) {
      AppExceptionHandler.handleResponse(e);
    } finally {
      isUpdating.value = false;
    }
  }

  @override
  void onClose() {
    oldPassword.dispose();
    newPassword.dispose();
    super.onClose();
  }
}
