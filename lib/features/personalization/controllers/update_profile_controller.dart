import 'package:matricmate/features/challenges/controllers/challenge_home_controller.dart';
import 'package:matricmate/features/exam/controllers/subjects_controller.dart';
import 'package:matricmate/features/personalization/controllers/analytics_controller.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matricmate/data/repositories/user/user_repository.dart';
import 'package:matricmate/data/services/fcm_service.dart';
import 'package:matricmate/features/personalization/controllers/user_controller.dart';
import 'package:matricmate/utils/exceptions/exception_handler.dart';
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
    selectedStream = (user.stream.isNotEmpty ? user.stream : 'natural').obs;
  }

  Future<void> updateProfile() async {
    try {
      if (!updateFormKey.currentState!.validate()) return;

      // Set button loading state IMMEDIATELY with 0ms delay
      isUpdating.value = true;

      final isConnected = await NetworkManager.instance.isConnected();

      if (!isConnected) {
        isUpdating.value = false;
        ToastHelper.warning('No Internet Connection');
        return;
      }

      final currentUser = _userController.user.value;

      final updatedUser = currentUser.copyWith(
        firstName: firstName.text.trim(),
        lastName: lastName.text.trim(),
        stream: selectedStream.value,
      );

      // Optimistic update
      _userController.user.value = updatedUser;

      // Update remote + local DB
      await _userRepository.updateFullUserRecord(updatedUser);

      // Refresh local state
      await _userController.loadLocalUser();

      // Re-save FCM token for the (potentially new) stream
      unawaited(FcmService.instance.saveTokenForCurrentUser());

      // Trigger automatic reload in all stream-dependent controllers
      if (Get.isRegistered<SubjectsController>()) {
        SubjectsController.instance.selectedStream.value = updatedUser.stream;
      }
      if (Get.isRegistered<ChallengeHomeController>()) {
        ChallengeHomeController.instance.loadAllChallenges(showLoading: false);
      }
      if (Get.isRegistered<AnalyticsController>()) {
        AnalyticsController.instance.loadAll();
      }

      Get.back();

      ToastHelper.success('Profile updated successfully');
    } catch (e) {
      await _userController.loadLocalUser();
      AppExceptionHandler.handleResponse(e);
    } finally {
      isUpdating.value = false;
    }
  }

  @override
  void onClose() {
    firstName.dispose();
    lastName.dispose();
    super.onClose();
  }
}
