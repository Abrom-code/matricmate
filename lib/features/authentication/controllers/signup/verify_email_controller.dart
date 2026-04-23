import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:matricmate/common/widgets/success_screen/success_screen.dart';
import 'package:matricmate/data/repositories/authentication/authentication_repository.dart';
import 'package:matricmate/utils/constants/app_strings.dart';
import 'package:matricmate/utils/helpers/toast_helper.dart';

class VerifyEmailController extends GetxController {
  static VerifyEmailController get instance => Get.find();

  final isEmailVerified = false.obs;

  @override
  void onInit() {
    sendEmailVerification();
    setTimerForAutoRedirect();
    super.onInit();
  }

  Future<void> sendEmailVerification() async {
    try {
      await AuthenticationRepository.instance.sendEmailVerification();
      ToastHelper.success("Email sent", "Please check your inbox!");
    } catch (e) {
      ToastHelper.error("Oh!", e.toString());
    }
  }

  void setTimerForAutoRedirect() {
    Timer.periodic(const Duration(seconds: 2), (timer) async {
      try {
        await FirebaseAuth.instance.currentUser?.reload();
        final user = FirebaseAuth.instance.currentUser;

        if (user?.emailVerified ?? false) {
          timer.cancel();
          Get.offAll(
            () => SuccessScreen(
              title: "Email Verified",
              subTitle: "You have verified your Email.",
              onPressed: () =>
                  AuthenticationRepository.instance.screenRedirect(),
            ),
          );
        }
      } catch (e) {
        rethrow;
      }
    });
  }

  void checkEmailVerification() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.emailVerified) {
      Get.offAll(
        () => SuccessScreen(
          title: AppTextStrings.yourAccountCreatedTitle,
          subTitle: "Account created",
          onPressed: () => AuthenticationRepository.instance.screenRedirect(),
        ),
      );
    }
  }
}
