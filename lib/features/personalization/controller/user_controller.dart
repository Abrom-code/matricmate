import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:matricmate/common/widgets/dialogs/confirm_dialog_box.dart';
import 'package:matricmate/common/widgets/loaders/full_screen_loader.dart';
import 'package:matricmate/data/repositories/authentication/authentication_repository.dart';
import 'package:matricmate/data/repositories/user/user_repository.dart';
import 'package:matricmate/features/authentication/controllers/authentication_controller.dart';
import 'package:matricmate/features/authentication/models/user_model.dart';
import 'package:matricmate/features/authentication/screens/login/login.dart';
import 'package:matricmate/navigation_menu.dart';
import 'package:matricmate/utils/exceptions/app_failure_model.dart';
import 'package:matricmate/utils/helpers/toast_helper.dart';

class UserController extends GetxController {
  static UserController get instance => Get.find();

  final AuthenticationRepository _authRepo =
      Get.find<AuthenticationRepository>();

  final UserRepository _userRepository = Get.find<UserRepository>();


  Rx<UserModel> user = UserModel.empty().obs;

  final RxBool isDeleting = false.obs;
  final userFetching = false.obs;

  @override
  void onInit() {
    super.onInit();

    // only react to auth changes
    _authRepo.userChanges.listen((firebaseUser) {
      if (firebaseUser != null) {
        fetchUserRecord();
      }
    });
  }

  Future<void> logOut() async {
    try {
      Get.back();
      AppFullScreenLoader.openLoadingDialog("Logging out...");

      await _authRepo.logout();

      user.value = UserModel.empty();

      AppFullScreenLoader.stopLoading();

      Get.offAll(() => const LoginScreen());
    } catch (e) {
      AppFullScreenLoader.stopLoading();
      if (e is AppFailure) {
        ToastHelper.error(e.title, e.message);
      } else {
        ToastHelper.error("Unexpected Error", e.toString());
      }
    }
  }

  Future<void> fetchUserRecord() async {
    try {
      userFetching.value = true;

      final freshUser = await _userRepository.fetchCurrentUserDetails();

      if (freshUser == null) return;

      user.value = freshUser;

      await _userRepository.addUser(freshUser);
    } catch (e) {
      AppFullScreenLoader.stopLoading();
      if (e is AppFailure) {
        ToastHelper.error(e.title, e.message);
      } else {
        ToastHelper.error("Unexpected Error", e.toString());
      }
    } finally {
      userFetching.value = false;
    }
  }

  Future<void> checkPaymentStatus() async {
    final current = user.value;

    if (current.isActive) {
      Get.offAll(() => NavigationMenu());
      ToastHelper.success("Success", "Your account is activated!");
      return;
    }

    if (current.isPending) {
      ToastHelper.warning("Progress", "Your payment is still processing!");
    }
  }

  Future<void> saveUserRecord(UserCredential? userCredentials) async {
    try {
      if (userCredentials == null) return;

      final nameParts = UserModel.nameParts(
        userCredentials.user?.displayName ?? "",
      );

      final newUser = UserModel(
        id: userCredentials.user!.uid,
        firstName: nameParts.first,
        lastName: nameParts.last,
        email: userCredentials.user?.email ?? "",
        stream: 'natural',
      );

      await _userRepository.saveUserRecord(newUser);
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

          final authUser = _authRepo.currentUser;

          if (authUser == null) return;

          await _userRepository.deleteUserRecord(authUser.uid);

          await authUser.delete();

          AppFullScreenLoader.stopLoading();

          user(UserModel.empty());

          Get.offAll(() => const LoginScreen());
        } catch (e) {
          AppFullScreenLoader.stopLoading();
          AppFullScreenLoader.stopLoading();
          if (e is AppFailure) {
            ToastHelper.error(e.title, e.message);
          } else {
            ToastHelper.error("Unexpected Error", e.toString());
          }
        }
      },
    );
  }

  Future<void> deleteUserAccount() async {
    try {
      showDeleteDialog();
    } catch (e) {
      AppFullScreenLoader.stopLoading();
      if (e is AppFailure) {
        ToastHelper.error(e.title, e.message);
      } else {
        ToastHelper.error("Unexpected Error", e.toString());
      }
    }
  }

  void showDeleteDialog() {
    final passwordController = TextEditingController();

    Get.defaultDialog(
      title: "Delete Account",
      content: Column(
        children: [
          const Text("Enter your password to confirm"),
          const SizedBox(height: 10),
          TextField(controller: passwordController, obscureText: true),
        ],
      ),
      confirm: Obx(
        () => ElevatedButton(
          onPressed: () async {
            try {
              isDeleting.value = true;

              await Get.find<AuthenticationController>().deleteAccount(
                passwordController.text.trim(),
              );

              Get.back();

              ToastHelper.success(
                "Account Deleted",
                "Your data has been permanently removed.",
              );
            } catch (e) {
              throw e;
            } finally {
              isDeleting.value = false;
            }
          },
          child: isDeleting.value
              ? const CircularProgressIndicator()
              : const Text("Delete"),
        ),
      ),
    );
  }
}
