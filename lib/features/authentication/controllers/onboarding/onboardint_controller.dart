import 'package:flutter/material.dart';
import 'package:get/get_instance/get_instance.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:get/state_manager.dart';
import 'package:matricmate/features/exam/controllers/subjects_controller.dart';
import 'package:matricmate/navigation_menu.dart';
// import 'package:shop/features/authentication/screens/login/login.dart';

class OnboardintController extends GetxController {
  static OnboardintController get instance => Get.find();

  final pageController = PageController();
  Rx<int> currentPageIndex = 0.obs;

  void updagePageIndicator(int index) => currentPageIndex.value = index;

  void dotNavigationClick(int index) {
    currentPageIndex.value = index;
    pageController.jumpTo(index.toDouble());
  }

  Future<void> nextPage() async {
    if (currentPageIndex.value == 2) {
      // GetStorage().write("isFirstTime", false);
      final subjectController = Get.find<SubjectsController>();
      await subjectController.loadSubjects();
      Get.offAll(const NavigationMenu());
    } else {
      int page = currentPageIndex.value + 1;
      pageController.jumpToPage(page);
    }
  }

  Future<void> skipPage() async {
    // GetStorage().write("isFirstTime", false);
    final subjectController = Get.find<SubjectsController>();
    await subjectController.loadSubjects();
    Get.offAll(const NavigationMenu());
  }
}
