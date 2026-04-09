import 'package:flutter/material.dart';
import 'package:get/get_instance/get_instance.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:get/state_manager.dart';
import 'package:get_storage/get_storage.dart';
import 'package:matricmate/features/exam/screens/subject/subjects.dart';
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

  void nextPage() {
    if (currentPageIndex.value == 2) {
      // GetStorage().write("isFirstTime", false);
      Get.offAll(const NavigationMenu());
    } else {
      int page = currentPageIndex.value + 1;
      pageController.jumpToPage(page);
    }
  }

  void skipPage() {
    GetStorage().write("isFirstTime", false);
    Get.offAll(const NavigationMenu());
  }
}
