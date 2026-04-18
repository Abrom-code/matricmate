import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matricmate/data/repositories/authentication/authentication_repository.dart';
import 'package:matricmate/utils/helpers/toast_helper.dart';
import 'package:matricmate/utils/network_manager/network_manager.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChangePasswordController extends GetxController {
  static ChangePasswordController get instance => Get.find();

  final hideOldPassword = true.obs;
  final hideNewPassword = true.obs;
  final isUpdating = false.obs;
  final GlobalKey<FormState> changePasswordKey = GlobalKey<FormState>();

  final oldPassword = TextEditingController();
  final newPassword = TextEditingController();

  Future<void> changePassword() async {
    try {
      isUpdating.value = true;

      final isConnected = await NetworkManager.instance.hasRealInternet();
      if (!isConnected) {
        isUpdating.value = false;
        ToastHelper.warning("No Internet", "Please check your connection.");
        return;
      }

      if (!changePasswordKey.currentState!.validate()) {
        isUpdating.value = false;
        return;
      }

      final email = AuthenticationRepository.instance.authUser?.email;
      AuthCredential credential = EmailAuthProvider.credential(
        email: email!,
        password: oldPassword.text.trim(),
      );

      await FirebaseAuth.instance.currentUser!.reauthenticateWithCredential(
        credential,
      );

      await AuthenticationRepository.instance.updateUserPassword(
        newPassword.text.trim(),
      );

      oldPassword.clear();
      newPassword.clear();
      Get.back();
      Get.back();
      ToastHelper.success("Success", "Your password has been updated.");
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password') {
        ToastHelper.error(
          "Error",
          "The current password you entered is incorrect.",
        );
      } else {
        ToastHelper.error("Error", e.message ?? "Authentication failed.");
      }
    } catch (e) {
      ToastHelper.error("Error", e.toString());
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
