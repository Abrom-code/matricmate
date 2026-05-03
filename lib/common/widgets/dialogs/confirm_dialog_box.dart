import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';

class AppDialogBoxes {
  static void showOkCancelDialog({
    required BuildContext context,
    String? title,
    String? subtitle,
    required VoidCallback onPressed,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title ?? "Confirm Action"),
          content: Text(subtitle ?? "Are you sure you want to proceed?"),
          actions: <Widget>[
            // Cancel Button
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),

            // OK Button
            TextButton(
              onPressed: () => onPressed(),
              child: const Text(
                "OK",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  static Future<bool?> changeDevice(
    String email,
    Future<void> Function() onConfirm,
  ) {
    return Get.dialog<bool>(
      AlertDialog(
        title: const Text("Changed Phone?"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "It looks like you're using a new device.",
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 14),

              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  "⚠️ Warning: Confirming will log out your previous device and block it from accessing this account.",
                  style: TextStyle(fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                "If this isn't yours, cancel and enter your credentials.",
                style: TextStyle(fontSize: 11, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),

        actions: [
          TextButton(
            onPressed: () {
              Get.back(result: false);
            },
            child: const Text("Cancel"),
          ),

          ElevatedButton(
            onPressed: () async {
              await onConfirm();
              Get.back(result: true);
            },
            child: const Text("Update"),
          ),
        ],
      ),
    );
  }
}
