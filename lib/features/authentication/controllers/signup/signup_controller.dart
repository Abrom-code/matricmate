import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matricmate/data/repositories/authentication/authentication_repository.dart';
import 'package:matricmate/data/repositories/user/user_repository.dart';
import 'package:matricmate/features/authentication/models/user_model.dart';
import 'package:matricmate/features/authentication/screens/signup/verify_email.dart';
import 'package:matricmate/utils/constants/api_constants.dart';
import 'package:matricmate/utils/helpers/toast_helper.dart';
import 'package:matricmate/utils/network_manager/network_manager.dart';

class SignupController extends GetxController {
  static SignupController get instance => Get.find();

  final hidePassword = true.obs;
  final isTermsAgreed = false.obs;
  final firstName = TextEditingController();
  final lastName = TextEditingController();
  final userName = TextEditingController();
  final email = TextEditingController();
  final phoneNumber = TextEditingController();
  final password = TextEditingController();

  GlobalKey<FormState> signupFormKey = GlobalKey<FormState>();

  void signup() async {
    try {
      if (!signupFormKey.currentState!.validate()) return;

      if (!isTermsAgreed.value) {
        ToastHelper.warning(
          "Warning",
          "Please read and accept the Privacy Policy & Terms of Use.",
        );
        return;
      }

      // 2. START LOADING
      // Open this BEFORE the network check so the user knows the app is "thinking."

      //  NETWORK CHECK
      final isConnected = await NetworkManager.instance.isConnected();
      if (!isConnected) {
        // Must stop if we return early
        return;
      }

      // REGISTER USER (Firebase)
      final userCredential = await AuthenticationRepository.instance
          .registerWithEmailAndPassword(
            email.text.trim(),
            password.text.trim(),
          );

      //  SAVE USER DATA
      final newUser = UserModel(
        id: '.user!.uid',
        firstName: firstName.text.trim(),
        lastName: lastName.text.trim(),
        email: email.text.trim(),
        stream: userName.text.trim(),
      );

      final userRepository = Get.put(UserRepository());
      await userRepository.saveUserRecord(newUser);

      Get.to(() => VerifyEmailScreen(email: email.text.trim()));
    } catch (e) {
      ToastHelper.error("Faild", e.toString());
    }
  }
}
