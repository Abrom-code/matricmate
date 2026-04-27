import 'dart:async';
import 'package:get/get.dart';
import 'package:matricmate/common/widgets/success_screen/success_screen.dart';
import 'package:matricmate/data/repositories/authentication/authentication_repository.dart';
import 'package:matricmate/features/authentication/controllers/authentication_controller.dart';
import 'package:matricmate/features/exam/controllers/syncing_controller.dart';
import 'package:matricmate/utils/exceptions/app_failure_model.dart';
import 'package:matricmate/utils/helpers/toast_helper.dart';

class VerifyEmailController extends GetxController {
  static VerifyEmailController get instance => Get.find();

  final AuthenticationController _authController =
      Get.find<AuthenticationController>();

  final AuthenticationRepository _authRepo =
      Get.find<AuthenticationRepository>();

  final isLoading = false.obs;

  Timer? _timer;

  bool _hasSynced = false;

  @override
  void onInit() {
    super.onInit();
    sendEmailVerification();
    startEmailVerificationWatcher();
  }

  Future<void> sendEmailVerification() async {
    try {
      await _authRepo.sendEmailVerification();
      ToastHelper.success("Email sent", "Please check your inbox!");
    } catch (e) {
      _handleError(e);
    }
  }

  void startEmailVerificationWatcher() {
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      try {
        isLoading.value = true;

        await _authRepo.reloadUser();

        final user = _authRepo.currentUser;

        if (user?.emailVerified ?? false) {
          timer.cancel();

          // prevent double sync
          if (!_hasSynced) {
            _hasSynced = true;
            await SyncingController.instance.syncAll();
          }

          isLoading.value = false;

          Get.offAll(
            () => SuccessScreen(
              title: "Email Verified",
              subTitle: "Your account is now active.",
              onPressed: () => _authController.screenRedirect(),
            ),
          );
        }
      } catch (e) {
        isLoading.value = false;
        _handleError(e);
      }
    });
  }

  //  Manual button check
  void checkEmailVerification() async {
    try {
      isLoading.value = true;

      await _authRepo.reloadUser();

      final user = _authRepo.currentUser;

      if (user != null && user.emailVerified) {
        if (!_hasSynced) {
          _hasSynced = true;
          await SyncingController.instance.syncAll();
        }

        Get.offAll(
          () => SuccessScreen(
            title: "Account Created",
            subTitle: "Account created successfully",
            onPressed: () => _authController.screenRedirect(),
          ),
        );
      } else {
        ToastHelper.warning("Not verified", "Please verify your email first");
      }
    } catch (e) {
      _handleError(e);
    } finally {
      isLoading.value = false;
    }
  }

  void _handleError(dynamic e) {
    if (e is AppFailure) {
      ToastHelper.error(e.title, e.message);
    } else {
      ToastHelper.error("Unexpected Error", e.toString());
    }
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }
}
