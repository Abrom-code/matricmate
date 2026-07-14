import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:matricmate/common/widgets/loaders/circular_loading.dart';
import 'package:matricmate/common/widgets/loaders/full_screen_loader.dart';
import 'package:matricmate/data/repositories/authentication/authentication_repository.dart';
import 'package:matricmate/data/repositories/user/user_repository.dart';
import 'package:matricmate/data/services/device_service.dart';
import 'package:matricmate/data/services/session_service.dart';
import 'package:matricmate/features/authentication/controllers/authentication_controller.dart';
import 'package:matricmate/features/authentication/models/user_model.dart';
import 'package:matricmate/navigation_menu.dart';
import 'package:matricmate/routes/app_routes.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/exceptions/exeption_handler.dart';
import 'package:matricmate/utils/helpers/snackbar_helper.dart';
import 'package:matricmate/utils/helpers/toast_helper.dart';

class UserController extends GetxController {
  static UserController get instance => Get.find();

  final AuthenticationRepository _authRepo =
      Get.find<AuthenticationRepository>();

  final UserRepository _userRepository = Get.find<UserRepository>();

  Rx<UserModel> user = UserModel.empty().obs;

  final RxBool isDeleting = false.obs;
  final userFetching = false.obs;
  final isPasswordHidden = true.obs;
  final RxBool isCheckingPayment = false.obs;

  @override
  void onInit() {
    super.onInit();

    _authRepo.userChanges.listen((firebaseUser) async {
      if (firebaseUser != null) {
        await loadLocalUser();
      } else {
        user.value = UserModel.empty();
      }
    });
  }

  Future<void> loadLocalUser() async {
    try {
      final local = await _userRepository.getLocalUser();

      if (local != null) {
        user.value = local;
      }
    } catch (e) {
      AppExceptionHandler.handleResponse(e);
    }
  }

  Future<void> logOut() async {
    try {
      AppFullScreenLoader.openLoadingDialog('Logging out...');

      await _authRepo.logout();

      user.value = UserModel.empty();

      AppFullScreenLoader.stopLoading();
      final nav = Get.find<NavigationController>();
      nav.selectedIdx.value = 0;
      Get.offAllNamed(Routes.signIn);
    } catch (e) {
      AppFullScreenLoader.stopLoading();
      AppExceptionHandler.handleResponse(e);
    }
  }

  Future<bool> fetchUserRecord() async {
    try {
      userFetching.value = true;

      final freshUser = await _userRepository.fetchCurrentUserDetails();

      if (freshUser == null) return false;

      final uid = _authRepo.currentUser!.uid;

      final deviceId = await DeviceService.getDeviceId();

      final isAllowed = await SessionService().validateSession(uid, deviceId);

      if (!isAllowed) {
        SnackbarHelper.warning(
          'Device Blocked!',
          'Another device is using this account!',
        );
        await logOut();
        return false;
      }

      user.value = freshUser;
      await _userRepository.updateLocalUser(freshUser);

      return true;
    } finally {
      userFetching.value = false;
    }
  }

  Future<void> checkPaymentStatus() async {
    try {
      isCheckingPayment.value = true;
      await fetchUserRecord();
      final current = user.value;

      if (current.isActive) {
        Get.offAll(() => const NavigationMenu());
        ToastHelper.success('Your account is activated!');
        return;
      }

      if (current.isPending) {
        SnackbarHelper.warning('Progress', 'Your payment is still processing!');
      }
    } finally {
      isCheckingPayment.value = false;
    }
  }

  Future<void> saveUserRecord(UserCredential? userCredentials) async {
    try {
      if (userCredentials == null) return;

      final nameParts = UserModel.nameParts(
        userCredentials.user?.displayName ?? '',
      );

      final newUser = UserModel(
        id: userCredentials.user!.uid,
        firstName: nameParts.first,
        lastName: nameParts.last,
        email: userCredentials.user?.email ?? '',
        stream: 'natural',
      );

      await _userRepository.saveUserRecord(newUser);
    } catch (e) {
      SnackbarHelper.warning('Data not saved', 'Something went wrong');
    }
  }

  void showDeleteDialog() {
    final passwordController = TextEditingController();

    Get.defaultDialog(
      titlePadding: const EdgeInsets.only(top: 18.0),
      title: 'Delete Account',
      content: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            const Text('Enter your password to confirm'),
            const SizedBox(height: 10),
            Obx(
              () => TextField(
                controller: passwordController,
                obscureText: isPasswordHidden.value,
                decoration: InputDecoration(
                  suffixIcon: IconButton(
                    onPressed: () =>
                        isPasswordHidden.value = !isPasswordHidden.value,
                    icon: Icon(
                      !isPasswordHidden.value
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      confirm: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SizedBox(
          width: double.infinity,
          child: Obx(
            () => OutlinedButton(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                side: const BorderSide(color: AppColors.error),
              ),
              onPressed: isDeleting.value
                  ? null
                  : () async {
                      try {
                        isDeleting.value = true;

                        await Get.find<AuthenticationController>()
                            .deleteAccount(passwordController.text.trim());

                        Get.back();

                        SnackbarHelper.success(
                          'Account Deleted',
                          'Your data has been permanently removed.',
                        );
                      } catch (e) {
                        AppExceptionHandler.handleResponse(e);
                      } finally {
                        isDeleting.value = false;
                      }
                    },
              child: isDeleting.value
                  ? const AppCircularButtonLoading(color: AppColors.error)
                  : const Text(
                      'Delete',
                      style: TextStyle(color: AppColors.error),
                    ),
            ),
          ),
        ),
      ),
    ).then((_) => passwordController.dispose());
  }
}
