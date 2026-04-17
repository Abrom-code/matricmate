import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ToastHelper {
  ToastHelper._();

  static void success(String title, String message) {
    _showToast(
      title,
      message,
      backgroundColor: Colors.green,
      icon: Icons.check_circle,
    );
  }

  static void error(String title, String message) {
    _showToast(title, message, backgroundColor: Colors.red, icon: Icons.error);
  }

  static void warning(String title, String message) {
    _showToast(
      title,
      message,
      backgroundColor: Colors.orange,
      icon: Icons.warning,
    );
  }

  static void info(String title, String message) {
    _showToast(title, message, backgroundColor: Colors.blue, icon: Icons.info);
  }

  static void _showToast(
    String title,
    String message, {
    required Color backgroundColor,
    required IconData icon,
  }) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: backgroundColor..withOpacity(0.9),
      colorText: Colors.white,
      margin: const EdgeInsets.all(12),
      borderRadius: 12,
      icon: Icon(icon, color: Colors.white),
      duration: const Duration(seconds: 2),
      isDismissible: true,
      forwardAnimationCurve: Curves.easeOutBack,
      animationDuration: const Duration(milliseconds: 300),
    );
  }
}
