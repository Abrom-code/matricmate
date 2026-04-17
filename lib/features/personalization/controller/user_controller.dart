import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:matricmate/common/widgets/dialogs/confirm_dialog_box.dart';
import 'package:matricmate/common/widgets/loaders/full_screen_loader.dart';
import 'package:matricmate/data/repositories/user/user_repository.dart';
import 'package:matricmate/features/authentication/models/user_model.dart';
import 'package:matricmate/features/authentication/screens/login/login.dart';
import 'package:matricmate/utils/helpers/toast_helper.dart';

class UserController extends GetxController {
  static UserController get instance => Get.find();

  Rx<UserModel> user = UserModel.empty().obs;

  final userRepository = Get.put(UserRepository());
  final userFetching = false.obs;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      fetchUserRecord();
    });
  }

  Future<void> fetchUserRecord() async {
    try {
      userFetching.value = true;
      final user = await userRepository.fetchUserDetails();
      this.user(user);
      userFetching.value = false;
    } catch (e) {
      userFetching.value = false;
      user(UserModel.empty());
    }
  }

  Future<void> saveUserRecord(UserCredential? userCredentials) async {
    try {
      if (userCredentials != null) {
        final nameParts = UserModel.nameParts(
          userCredentials.user?.displayName ?? "",
        );

        final user = UserModel(
          id: userCredentials.user!.uid,
          firstName: nameParts.first,
          lastName: nameParts.last,
          email: userCredentials.user?.email ?? "",
          stream: 'natural',
        );
        await userRepository.saveUserRecord(user);
      }
    } catch (e) {
      ToastHelper.warning("Data not saved", "Something went wrong");
    }
  }

  Future<void> handleDeleteAccount(BuildContext context) async {
    AppDialogBoxes.showOkCancelDialog(
      context: context,
      onPressed: () async {
        try {
          AppFullScreenLoader.openLoadingDialog("Deleting account...");

          final authUser = FirebaseAuth.instance.currentUser;

          if (authUser != null) {
            await userRepository.deleteUserRecord(user.value.id);

            await authUser.delete();

            AppFullScreenLoader.stopLoading();

            user(UserModel.empty());

            Get.offAll(() => const LoginScreen());
          }
        } on FirebaseAuthException catch (e) {
          AppFullScreenLoader.stopLoading();
          if (e.code == 'requires-recent-login') {
            await FirebaseAuth.instance.signOut();
            Get.offAll(() => const LoginScreen());
            ToastHelper.warning(
              "Session Expired",
              "Please log in again to verify it's you.",
            );
          } else {
            ToastHelper.error("Error", e.message ?? "Delete failed");
          }
        } catch (e) {
          AppFullScreenLoader.stopLoading();
          ToastHelper.error("Error", "Failed to delete account!");
        }
      },
    );
  }
}
