import 'package:get/get.dart';
import 'package:matricmate/features/authentication/controllers/login/login_controller.dart';

class LoginBinding extends Bindings {
  @override
  void dependencies() {
    if (Get.isRegistered<LoginController>()) {
      Get.delete<LoginController>(force: true);
    }
    Get.lazyPut<LoginController>(
      () => LoginController(),
      fenix: true,
    );
  }
}
