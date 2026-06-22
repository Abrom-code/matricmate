import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ThemeController extends GetxController {
  static ThemeController get instance => Get.find();
  final themeMode = ThemeMode.system.obs;

  void toggleTheme(bool value) {
    if (value) {
      themeMode.value = ThemeMode.dark;
    } else {
      themeMode.value = ThemeMode.light;
    }
  }
}
