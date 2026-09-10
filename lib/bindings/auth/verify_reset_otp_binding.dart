import 'package:get/get.dart';
import 'package:matricmate/features/authentication/controllers/login/verify_reset_otp_controller.dart';

class VerifyResetOtpBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<VerifyResetOtpController>(
      () => VerifyResetOtpController(),
      fenix: true,
    );
  }
}
