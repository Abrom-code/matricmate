import 'package:get/get.dart';
import 'package:matricmate/data/repositories/authentication/authentication_repository.dart';
import 'package:matricmate/utils/helpers/toast_helper.dart';

class ResetPasswordController extends GetxController {
  static ResetPasswordController get instance => Get.find();

  Future<void> sendResetEmail(String email) async {
    try {
      await AuthenticationRepository.instance.sendResetPasswordEmail(email);
      ToastHelper.success("Email sent", "Please check your inbox!");
    } catch (e) {
      ToastHelper.error("Oh!", e.toString());
    }
  }
}
