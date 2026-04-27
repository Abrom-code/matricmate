import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matricmate/data/repositories/user/user_repository.dart';
import 'package:matricmate/features/personalization/controller/user_controller.dart';
import 'package:matricmate/utils/helpers/toast_helper.dart';
import 'package:matricmate/utils/network_manager/network_manager.dart';

class UpdateProfileController extends GetxController {
  static UpdateProfileController get instance => Get.find();

  final UserRepository _userRepository = Get.find<UserRepository>();
  final UserController _userController = Get.find<UserController>();

  late TextEditingController firstName;
  late TextEditingController lastName;
  late RxString selectedStream;

  final RxBool isUpdating = false.obs;

  GlobalKey<FormState> updateFormKey = GlobalKey<FormState>();

  @override
  void onInit() {
    super.onInit();

    final user = _userController.user.value;

    firstName = TextEditingController(text: user.firstName);
    lastName = TextEditingController(text: user.lastName);
    selectedStream = user.stream.obs;
  }

  Future<void> updateProfile() async {
    try {
      if (!updateFormKey.currentState!.validate()) return;

      final isConnected = await NetworkManager.instance.hasRealInternet();

      if (!isConnected) {
        ToastHelper.warning("No Internet", "Check your connection.");
        return;
      }

      isUpdating.value = true;

      final currentUser = _userController.user.value;

      final updatedUser = currentUser.copyWith(
        firstName: firstName.text.trim(),
        lastName: lastName.text.trim(),
        stream: selectedStream.value,
      );

      // 1. update remote + local DB
      await _userRepository.updateFullUserRecord(updatedUser);

      // 2. single source refresh (correct way)
      await _userController.fetchUserRecord();

      Get.back();

      ToastHelper.success("Success", "Profile updated successfully");
    } catch (e) {
      ToastHelper.error("Error", e.toString());
    } finally {
      isUpdating.value = false;
    }
  }
}
