import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matricmate/common/widgets/loaders/circular_loading.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

/// A utility class for managing a full-screen loading overlay.
class AppFullScreenLoader {
  static bool _isLoading = false;

  static bool get isLoading => _isLoading;

  /// Opens a clean full-screen loading dialog with 3 pulsing dots and subtitle text (no box/card).
  static void openLoadingDialog(String text, [String? _]) {
    if (_isLoading) return;

    final context = Get.overlayContext ?? Get.context;
    if (context == null) return;

    _isLoading = true;
    final dark = AppHelperFunctions.isDark(context);

    showDialog(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: dark ? 0.75 : 0.55),
      builder: (_) => PopScope(
        canPop: false,
        child: Center(
          child: Material(
            color: Colors.transparent,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ── 3 Pulsing Dots Indicator ────────────────────────
                const AppPulsingDots(
                  dotSize: 10,
                  dotSpacing: 5,
                  color: Colors.white,
                ),
                if (text.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  // ── Subtitle text ──────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      text,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.2,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    ).then((_) {
      _isLoading = false;
    });
  }

  static void stopLoading() {
    if (!_isLoading) {
      try {
        if (Get.isDialogOpen ?? false) {
          Get.back();
        }
      } catch (_) {}
      return;
    }

    _isLoading = false;

    try {
      final context = Get.overlayContext ?? Get.context;
      if (context != null) {
        final nav = Navigator.of(context, rootNavigator: true);
        if (nav.canPop()) {
          nav.pop();
          return;
        }
      }
    } catch (_) {}

    try {
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }
    } catch (_) {}
  }
}
