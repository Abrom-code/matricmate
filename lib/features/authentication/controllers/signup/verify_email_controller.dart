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

  final isChecking = false.obs;
  final isResending = false.obs;

  Timer? _timer;

  bool _hasSynced = false;
  final email = ''.obs;

  @override
  void onInit() {
    super.onInit();
    email.value = Get.arguments['email'] ?? '';
    sendEmailVerification();
  }

  Future<void> sendEmailVerification() async {
    try {
      isResending.value = true;
      await _authRepo.sendEmailVerification();
      ToastHelper.success("Email sent", "Please check your inbox!");
    } catch (e) {
      AppExceptionHandler.handleResponse(e);
    } finally {
      isResending.value = false;
    }
  }

  Future<void> checkEmailVerification() async {
    try {
      isChecking.value = true;

      await _authRepo.reloadUser();
      final user = _authRepo.currentUser;

      if (user != null && user.emailVerified) {
        if (!_hasSynced) {
          _hasSynced = true;
          await SyncingController.instance.syncAll();
        }

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
    } finally {
      isChecking.value = false;
    }
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }
}
