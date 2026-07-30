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
import 'package:matricmate/utils/exceptions/exception_handler.dart';
import 'package:matricmate/utils/helpers/snackbar_helper.dart';
import 'package:matricmate/utils/helpers/toast_helper.dart';

class UserController extends GetxController {
  static UserController get instance => Get.find();

  final AuthenticationRepository _authRepo =
      Get.find<AuthenticationRepository>();

  final UserRepository _userRepository = Get.find<UserRepository>();

  /// Kept as a field so we can cancel the realtime watch on logout.
  final _sessionService = SessionService();

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

      // Stop watching the session before signing out so we don't
      // receive a stale change event during teardown.
      _sessionService.cancelWatch();

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

      final isAllowed = await _sessionService.validateSession(uid, deviceId);

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

      // Start (or restart) the Realtime watch now that we know this device
      // is authorised. If the admin changes the device_id in Supabase,
      // this callback fires and the user is immediately logged out.
      _sessionService.watchSession(
        uid: uid,
        currentDeviceId: deviceId,
        onDeviceChanged: () {
          SnackbarHelper.warning(
            'Session Ended',
            'Your account was signed in on another device.',
          );
          logOut();
        },
      );

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
    Get.dialog(const _DeleteAccountDialog(), barrierDismissible: true);
  }
}

// ── Delete account dialog ─────────────────────────────────────────────────────
// Self-contained StatefulWidget so the TextEditingController and local
// visibility state are tied to the widget lifecycle — no leaks when dismissed.

class _DeleteAccountDialog extends StatefulWidget {
  const _DeleteAccountDialog();

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  final _passwordController = TextEditingController();
  bool _obscure = true;
  bool _deleting = false;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_deleting) return;
    setState(() => _deleting = true);
    try {
      await Get.find<AuthenticationController>().deleteAccount(
        _passwordController.text.trim(),
      );
      if (mounted) Get.back();
      SnackbarHelper.success(
        'Account Deleted',
        'Your data has been permanently removed.',
      );
    } catch (e) {
      AppExceptionHandler.handleResponse(e);
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Delete Account',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text('Enter your password to confirm'),
            const SizedBox(height: 12),
            TextField(
              controller: _passwordController,
              obscureText: _obscure,
              decoration: InputDecoration(
                suffixIcon: IconButton(
                  onPressed: () => setState(() => _obscure = !_obscure),
                  icon: Icon(
                    _obscure ? Icons.visibility_off : Icons.visibility,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  side: const BorderSide(color: AppColors.error),
                ),
                onPressed: _deleting ? null : _submit,
                child: _deleting
                    ? const AppCircularButtonLoading(color: AppColors.error)
                    : const Text(
                        'Delete',
                        style: TextStyle(color: AppColors.error),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
