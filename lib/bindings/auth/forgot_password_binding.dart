import 'package:get/get.dart';
import 'package:matricmate/features/authentication/controllers/login/forget_password_controller.dart';

class ForgotPasswordBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ForgetPasswordController>(() => ForgetPasswordController());
  }
}
