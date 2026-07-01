import 'package:get/get.dart';
import 'package:matricmate/features/authentication/controllers/signup/signup_controller.dart';

class SignupBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SignupController>(() => SignupController(), fenix: true);
  }
}
