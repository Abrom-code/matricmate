import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matricmate/data/repositories/authentication/authentication_repository.dart';
import 'package:matricmate/data/repositories/user/user_repository.dart';
import 'package:matricmate/data/services/device_service.dart';
import 'package:matricmate/data/services/session_service.dart';
import 'package:matricmate/features/authentication/models/user_model.dart';
import 'package:matricmate/routes/app_routes.dart';
import 'package:matricmate/utils/exceptions/exeption_handler.dart';
import 'package:matricmate/utils/helpers/toast_helper.dart';
import 'package:matricmate/utils/network_manager/network_manager.dart';

class SignupController extends GetxController {
  static SignupController get instance => Get.find();
  final AuthenticationRepository _authenticationRepository =
      AuthenticationRepository();

  final hidePassword = true.obs;
  final firstName = TextEditingController();
  final lastName = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  final RxString selectedStream = ''.obs;
  final RxBool isSigning = false.obs;

  GlobalKey<FormState> signupFormKey = GlobalKey<FormState>();

  void setStream(String stream) {
    selectedStream.value = stream;
  }

  void signup() async {
    try {
      if (!signupFormKey.currentState!.validate()) return;
      if (selectedStream.value.isEmpty) {
        ToastHelper.warning('Please select stream, you can edit later!');
        return;
      }

      final isConnectd = await NetworkManager.instance.hasRealInternet();
      if (!isConnectd) {
        ToastHelper.warning('No Internet!');
        return;
      }
      isSigning.value = true;

      // REGISTER USER (Firebase)
      final userCredential = await _authenticationRepository
          .registerWithEmailAndPassword(
            email.text.trim(),
            password.text.trim(),
          );

      final uid = userCredential.user!.uid;

      //  SAVE USER DATA
      final newUser = UserModel(
        id: userCredential.user!.uid,
        firstName: firstName.text.trim(),
        lastName: lastName.text.trim(),
        email: email.text.trim(),
        stream: selectedStream.value.trim(),
      );

      final userRepository = Get.find<UserRepository>();
      await userRepository.saveUserRecord(newUser);

      final deviceId = await DeviceService.getDeviceId();

      final isAllowed = await SessionService().validateSession(uid, deviceId);

      if (!isAllowed) {
        await FirebaseAuth.instance.signOut();
        ToastHelper.error('Failed to register device. Please try again.');
        return;
      }
      Get.offAllNamed(
        Routes.verifyEmail,
        arguments: {'email': email.text.trim()},
      );
    } catch (e) {
      AppExceptionHandler.handleResponse(e);
    } finally {
      isSigning.value = false;
    }
  }
}
