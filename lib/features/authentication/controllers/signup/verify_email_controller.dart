import 'dart:async';
import 'package:get/get.dart';
import 'package:matricmate/common/widgets/success_screen/success_screen.dart';
import 'package:matricmate/data/repositories/authentication/authentication_repository.dart';
import 'package:matricmate/features/authentication/controllers/authentication_controller.dart';
import 'package:matricmate/utils/helpers/toast_helper.dart';

class VerifyEmailController extends GetxController {
  static VerifyEmailController get instance => Get.find();

  final AuthenticationController _authController =
      Get.find<AuthenticationController>();

  final AuthenticationRepository _authRepo =
      Get.find<AuthenticationRepository>();

  Timer? _timer;

  @override
  void onInit() {
    super.onInit();
    sendEmailVerification();
    setTimerForAutoRedirect();
  }

  Future<void> sendEmailVerification() async {
    try {
      await _authRepo.sendEmailVerification();
      ToastHelper.success("Email sent", "Please check your inbox!");
    } catch (e) {
      ToastHelper.error("Error", e.toString());
    }
  }

  void setTimerForAutoRedirect() {
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      try {
        await _authRepo.reloadUser();

        final user = _authRepo.currentUser;

        if (user?.emailVerified ?? false) {
          timer.cancel();

          Get.offAll(
            () => SuccessScreen(
              title: "Email Verified",
              subTitle: "You have verified your Email.",
              onPressed: () => _authController.screenRedirect(),
            ),
          );
        }
      } catch (e) {
        ToastHelper.error("Error", e.toString());
      }
    });
  }

  void checkEmailVerification() {
    final user = _authRepo.currentUser;

    if (user != null && user.emailVerified) {
      Get.offAll(
        () => SuccessScreen(
          title: "Account Created",
          subTitle: "Account created successfully",
          onPressed: () => _authController.screenRedirect(),
        ),
      );
    }
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }
}
