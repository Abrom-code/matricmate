import 'package:get/get.dart';
import 'package:matricmate/data/repositories/authentication/authentication_repository.dart';
import 'package:matricmate/utils/exceptions/exeption_handler.dart';
import 'package:matricmate/utils/helpers/toast_helper.dart';

class ResetPasswordController extends GetxController {
  static ResetPasswordController get instance => Get.find();
  final AuthenticationRepository _authenticationRepository =
      AuthenticationRepository();

  final isSending = false.obs;

  final email = ''.obs;
  @override
  void onInit() {
    email.value = Get.arguments['email'];
    super.onInit();
  }

  Future<void> sendResetEmail(String email) async {
    try {
      isSending.value = true;
      await _authenticationRepository.sendResetPasswordEmail(email);
      ToastHelper.success('Email sent, please check your inbox!');
    } catch (e) {
      AppExceptionHandler.handleResponse(e);
    } finally {
      isSending.value = false;
    }
  }
}
