import 'dart:async';

import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:matricmate/data/repositories/authentication/authentication_repository.dart';
import 'package:matricmate/data/repositories/user/user_repository.dart';
import 'package:matricmate/data/services/device_service.dart';
import 'package:matricmate/data/services/fcm_service.dart';
import 'package:matricmate/data/services/session_service.dart';
import 'package:matricmate/features/authentication/controllers/authentication_controller.dart';
import 'package:matricmate/features/authentication/models/user_model.dart';
import 'package:matricmate/navigation_menu.dart';
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

  StreamSubscription<User?>? _authSub;

  Rx<UserModel> user = UserModel.empty().obs;

  final RxBool isDeleting = false.obs;
  final userFetching = false.obs;
  final isPasswordHidden = true.obs;
  final RxBool isCheckingPayment = false.obs;

  @override
  void onInit() {
    super.onInit();

    _authSub = _authRepo.userChanges.listen((firebaseUser) async {
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

  void cancelSessionWatch() => _sessionService.cancelWatch();

  Future<void> logOut() async {
    await AuthenticationController.instance.logout();
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

      // Save FCM token now that userId is confirmed
      unawaited(FcmService.instance.saveTokenForCurrentUser());

      // Watch session — logout on device mismatch
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
        return;
      }

      // Inactive — pop to home so user sees premium banner
      Get.until((route) => route.isFirst);
      SnackbarHelper.warning(
        'Payment Not Approved',
        'Your payment was not approved. Please try again.',
      );
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

  @override
  void onClose() {
    _authSub?.cancel();
    cancelSessionWatch();
    super.onClose();
  }
}

// Delete account dialog (self-contained StatefulWidget)

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
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: dark ? AppColors.darkCard : AppColors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Warning icon container
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444)
                    .withValues(alpha: dark ? 0.22 : 0.12),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(
                  Icons.delete_forever_rounded,
                  color: Color(0xFFEF4444),
                  size: 26,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Delete Account',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Enter your password to permanently delete your account and all data.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: dark ? AppColors.darkGrey : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _passwordController,
              obscureText: _obscure,
              decoration: InputDecoration(
                hintText: 'Enter your password',
                prefixIcon: const Icon(Icons.lock_outline_rounded, size: 18),
                suffixIcon: IconButton(
                  onPressed: () => setState(() => _obscure = !_obscure),
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 18,
                  ),
                ),
                filled: true,
                fillColor: dark
                    ? const Color(0xFF151922)
                    : const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: dark
                        ? AppColors.darkBorder
                        : const Color(0xFFE2E8F0),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: dark
                        ? AppColors.darkBorder
                        : const Color(0xFFE2E8F0),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFFEF4444),
                    width: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(
                          color: dark
                              ? AppColors.darkBorder
                              : const Color(0xFFCBD5E1),
                        ),
                      ),
                      onPressed: _deleting ? null : () => Get.back(),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: dark ? AppColors.white : const Color(0xFF334155),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _deleting ? null : _submit,
                      child: _deleting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Delete',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
