import 'package:get/get.dart';
import 'package:matricmate/data/repositories/authentication/authentication_repository.dart';
import 'package:matricmate/features/authentication/controllers/authentication_controller.dart';
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
      ToastHelper.success('Email sent');
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
        ToastHelper.success('Email Verified');

        _authController.screenRedirect();
      } else {
        ToastHelper.warning('Not verified, please verify your email first');
      }
    } catch (e) {
      AppExceptionHandler.handleResponse(e);
    } finally {
      isChecking.value = false;
    }
  }

  @override
  void onClose() {
    super.onClose();
  }
}
