import 'package:get/get.dart';
import 'package:matricmate/features/authentication/controllers/signup/verify_email_controller.dart';

class EmailVerifyBinding extends Bindings {
  @override
  void dependencies() {
    // lazyPut + fenix because onInit reads Get.arguments (screen-specific)
    Get.lazyPut<VerifyEmailController>(
      () => VerifyEmailController(),
      fenix: true,
    );
  }
}
