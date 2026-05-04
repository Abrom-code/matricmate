import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matricmate/features/authentication/controllers/login/login_controller.dart';
import 'package:matricmate/features/exam/screens/premium/widgets/telegram_chat.dart';

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
    LoginController ctrl,
    Future<void> Function() onConfirm,
  ) {
    return Get.dialog<bool>(
      AlertDialog(
        title: const Text("Changed Phone?"),
        content: Obx(
          () => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                ctrl.trials.value <= 0
                    ? "You are out of device change trials!"
                    : "If this is your new device you can update it.\n"
                          "You have: ${ctrl.trials.value} trials",
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),

              if (ctrl.trials.value <= 0) TelegramChatButton(),

              if (ctrl.trials.value > 0)
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    "⚠️ Warning: Updating will log out previous device.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12),
                  ),
                ),

              const SizedBox(height: 10),

              const Text(
                "If this isn't yours, cancel.",
                style: TextStyle(fontSize: 11, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),

        actions: [
          Obx(
            () => TextButton(
              onPressed: ctrl.isUpdating.value
                  ? null
                  : () => Get.back(result: false),
              child: const Text("Cancel"),
            ),
          ),

          Obx(
            () => ElevatedButton(
              onPressed: ctrl.isUpdating.value || ctrl.trials.value <= 0
                  ? null
                  : () async {
                      ctrl.isUpdating.value = true;

                      try {
                        await onConfirm();

                        Get.back(result: true);
                      } catch (e) {
                        ctrl.isUpdating.value = false;
                        Get.snackbar("Error", e.toString());
                      }
                    },
              child: ctrl.isUpdating.value
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text("Update"),
            ),
          ),
        ],
      ),
    );
  }
}
