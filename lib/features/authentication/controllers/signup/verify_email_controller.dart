import 'dart:async';
import 'package:get/get.dart';
import 'package:matricmate/data/repositories/authentication/authentication_repository.dart';
import 'package:matricmate/features/authentication/controllers/authentication_controller.dart';
import 'package:matricmate/features/exam/controllers/syncing_controller.dart';
import 'package:matricmate/routes/app_routes.dart';
import 'package:matricmate/utils/exceptions/exeption_handler.dart';
import 'package:matricmate/utils/helpers/toast_helper.dart';

class VerifyEmailController extends GetxController {
  static VerifyEmailController get instance => Get.find();

  final AuthenticationController _authController =
      Get.find<AuthenticationController>();

  final AuthenticationRepository _authRepo =
      Get.find<AuthenticationRepository>();

  final isVerified = false.obs;

  Timer? _timer;

  bool _hasSynced = false;
  final email = ''.obs;

  @override
  void onInit() {
    super.onInit();
    email.value = Get.arguments['email'] ?? '';
    sendEmailVerification();
    startEmailVerificationWatcher();
  }

  Future<void> sendEmailVerification() async {
    try {
      await _authRepo.sendEmailVerification();
      ToastHelper.success("Email sent", "Please check your inbox!");
    } catch (e) {
      AppExceptionHandler.handleResponse(e);
    }
  }

  void startEmailVerificationWatcher() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      try {
        await _authRepo.reloadUser();

        final user = _authRepo.currentUser;

        if (user?.emailVerified ?? false) {
          timer.cancel();

          // prevent double sync
          if (!_hasSynced) {
            _hasSynced = true;
            await SyncingController.instance.syncAll();
          }

          Get.offAllNamed(
            Routes.success,

            arguments: {
              'title': "Email Verified",
              'sub_title': "Your account is now active.",
            },
          );
        }
      } catch (e) {
        AppExceptionHandler.handleResponse(e);
      }
    });
  }

  //  Manual button check
  void checkEmailVerification() async {
    try {
      await _authRepo.reloadUser();

      final user = _authRepo.currentUser;

      if (user != null && user.emailVerified) {
        if (!_hasSynced) {
          _hasSynced = true;
          await SyncingController.instance.syncAll();
        }
        isVerified.value = true;
        Get.offAllNamed(
          Routes.success,

          arguments: {
            'title': "Account Created",
            'sub_title': "Account created successfully",
            'on_pressed': () => _authController.screenRedirect(),
          },
        );
      } else {
        ToastHelper.warning("Not verified", "Please verify your email first");
      }
    } catch (e) {
      AppExceptionHandler.handleResponse(e);
    }
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }
}
