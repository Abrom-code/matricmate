import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:matricmate/common/widgets/dialogs/confirm_dialog_box.dart';
import 'package:matricmate/common/widgets/loaders/full_screen_loader.dart';
import 'package:matricmate/data/database/database_service.dart';
import 'package:matricmate/data/repositories/authentication/authentication_repository.dart';
import 'package:matricmate/data/repositories/user/user_repository.dart';
import 'package:matricmate/features/authentication/models/user_model.dart';
import 'package:matricmate/features/authentication/screens/login/login.dart';
import 'package:matricmate/utils/constants/sizes.dart';
import 'package:matricmate/utils/helpers/toast_helper.dart';
import 'package:matricmate/utils/logging/logging.dart';
import 'package:sqflite/sqflite.dart';

class UserController extends GetxController {
  static UserController get instance => Get.find();

  final DatabaseService _databaseService = DatabaseService.instance;
  Rx<UserModel> user = UserModel.empty().obs;
  final RxBool isDeleting = false.obs;

  final userRepository = Get.put(UserRepository());
  final userFetching = false.obs;

  @override
  void onInit() {
    super.onInit();

    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        fetchUserRecord();
      }
    });
  }

  Future<void> fetchUserRecord() async {
    try {
      userFetching.value = true;

      // 1. LOCAL FIRST (source of truth initially)
      final dbUser = await _databaseService.getUser();

      if (dbUser.isNotEmpty) {
        user.value = UserModel.fromMap(dbUser.first);
      }

      // 2. REMOTE SYNC
      final freshUser = await userRepository.fetchUserDetails();

      if (freshUser == null) return;

      // 3. ONLY UPDATE IF DIFFERENT (IMPORTANT FIX)
      if (freshUser.id != user.value.id ||
          freshUser.email != user.value.email ||
          freshUser.firstName != user.value.firstName) {
        user.value = freshUser;

        final db = await _databaseService.database;
        await db.insert(
          'user',
          freshUser.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    } catch (e) {
      AppLoggerHelper.error(e.toString());
    } finally {
      userFetching.value = false;
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

  Future<void> deleteUserAccount() async {
    showDeleteDialog();
  }

  void showDeleteDialog() {
    final passwordController = TextEditingController();

    Get.defaultDialog(
      titlePadding: EdgeInsets.only(top: AppSizes.md),
      contentPadding: EdgeInsets.all(AppSizes.md * 1.5),
      title: "Delete Account",
      content: Column(
        children: [
          const Text("Enter your password to confirm"),
          const SizedBox(height: 10),
          TextField(controller: passwordController, obscureText: true),
        ],
      ),
      confirm: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () async {
            try {
              isDeleting.value = true;

              await AuthenticationRepository.instance.deleteAccount(
                passwordController.text.trim(),
              );

              Get.back();

              ToastHelper.success(
                "Account Deleted",
                "Your data has been permanently removed.",
              );
            } catch (e) {
              ToastHelper.error("Error", e.toString());
            } finally {
              isDeleting.value = false;
            }
          },
          child: Obx(
            () => isDeleting.value
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: const CircularProgressIndicator(),
                  )
                : const Text("Delete"),
          ),
        ),
      ),
    );
  }
}
