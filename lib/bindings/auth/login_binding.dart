import 'package:get/get.dart';
import 'package:matricmate/features/authentication/controllers/login/login_controller.dart';

class LoginBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<LoginController>(() => LoginController());
  }
}
