import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/src/extension_instance.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';

class AuthenticationRepository extends GetxController {
  static AuthenticationRepository get instance => Get.find();

  @override
  void onReady() {
    // Remove splash screen

    screenRedirect();
  }

  /// Decide where to send the user based on Auth state
  void screenRedirect() {}

  /// Register
  Future<void> registerWithEmailAndPassword(
    String email,
    String password,
  ) async {}

  /// Email Verification
  Future<void> sendEmailVerification() async {}

  // Hande signin using login and password
  Future<void> loginUsingEmailAndPassword(
    String email,
    String password,
  ) async {}

  /// Handle logout
  Future<void> logout() async {}

  Future<void> sendResetPasswordEmail(String email) async {}
}
