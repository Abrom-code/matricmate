import 'package:get/get.dart';
import 'package:matricmate/features/authentication/controllers/login/login_controller.dart';

class LoginBinding extends Bindings {
  @override
  void dependencies() {
    // fenix: true — recreates the controller fresh each time the route
    // is visited, so TextEditingControllers are never reused after dispose.
    Get.lazyPut<LoginController>(() => LoginController(), fenix: true);
  }
}
