import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

/// A utility class for managing a full-screen loading dialog.
class AppFullScreenLoader {
  /// Opens a full-screen loading dialog with a built-in Material design spinner.
  static void openLoadingDialog(String text, [String? _]) {
    showDialog(
      context: Get.overlayContext!,
      barrierDismissible: false,
      builder: (_) => PopScope(
        canPop: false,
        child: Container(
          color: AppHelperFuntions.isDark(Get.context!)
              ? AppColors.dark
              : AppColors.white,
          width: double.infinity,
          height: double.infinity,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center, // Built-in centering
            children: [
              // Built-in Flutter Material Loader
              const CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 3,
              ),

              const SizedBox(height: 24),

              // Loading Text
              DefaultTextStyle(
                style: Theme.of(Get.context!).textTheme.bodyMedium!.copyWith(
                  color: AppHelperFuntions.isDark(Get.context!)
                      ? Colors.white
                      : Colors.black,
                  decoration: TextDecoration.none, // Removes yellow underlines
                ),
                child: Text(text, textAlign: TextAlign.center),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static void stopLoading() {
    Navigator.of(Get.overlayContext!).pop();
  }
}
