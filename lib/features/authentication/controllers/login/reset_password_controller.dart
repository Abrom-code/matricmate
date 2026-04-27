import 'package:get/get.dart';
import 'package:matricmate/data/repositories/authentication/authentication_repository.dart';
import 'package:matricmate/utils/exceptions/app_failure_model.dart';
import 'package:matricmate/utils/helpers/toast_helper.dart';

class ResetPasswordController extends GetxController {
  static ResetPasswordController get instance => Get.find();
  final AuthenticationRepository _authenticationRepository =
      AuthenticationRepository();

  Future<void> sendResetEmail(String email) async {
    try {
      await _authenticationRepository.sendResetPasswordEmail(email);
      ToastHelper.success("Email sent", "Please check your inbox!");
    } catch (e) {
      if (e is AppFailure) {
        ToastHelper.error(e.title, e.message);
      } else {
        ToastHelper.error("Unexpected Error", e.toString());
      }
    }
  }
}
