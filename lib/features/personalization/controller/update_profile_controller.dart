import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matricmate/data/repositories/user/user_repository.dart';
import 'package:matricmate/features/personalization/controller/user_controller.dart';
import 'package:matricmate/utils/helpers/toast_helper.dart';
import 'package:matricmate/utils/network_manager/network_manager.dart';

class UpdateProfileController extends GetxController {
  static UpdateProfileController get instance => Get.find();

  final userController = UserController.instance; // Use your instance getter
  final userRepository = UserRepository.instance;

  late final TextEditingController firstName;
  late final TextEditingController lastName;
  late final RxString selectedStream;
  final RxBool isUpdating = false.obs;

  GlobalKey<FormState> updateFormKey = GlobalKey<FormState>();

  @override
  void onInit() {
    super.onInit();
    firstName = TextEditingController(
      text: userController.user.value.firstName,
    );
    lastName = TextEditingController(text: userController.user.value.lastName);
    selectedStream = userController.user.value.stream.obs;
  }

  Future<void> updateProfile() async {
    try {
      if (!updateFormKey.currentState!.validate()) return;

      final isConnected = await NetworkManager.instance.hasRealInternet();
      if (!isConnected) {
        ToastHelper.warning("No Internet", "Check your connection.");
        return;
      }

      final updatedUser = userController.user.value.copyWith(
        firstName: firstName.text.trim(),
        lastName: lastName.text.trim(),
        stream: selectedStream.value,
      );
      isUpdating.value = true;

      await userRepository.updateFullUserRecord(updatedUser);

      userController.user.value = updatedUser;

      await userController.fetchUserRecord();
      isUpdating.value = false;
      Get.back();
      ToastHelper.success("Success", "Profile updated Successfully");
    } catch (e) {
      isUpdating.value = false;
      ToastHelper.error("Error", e.toString());
    }
  }
}
