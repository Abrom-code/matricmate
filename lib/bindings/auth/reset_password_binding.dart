import 'package:get/get.dart';
import 'package:matricmate/features/authentication/controllers/login/reset_password_controller.dart';

class ResetPasswordBinding extends Bindings {
  @override
  void dependencies() {
    // lazyPut + fenix because onInit reads Get.arguments (screen-specific)
    Get.lazyPut<ResetPasswordController>(
      () => ResetPasswordController(),
      fenix: true,
    );
  }
}
