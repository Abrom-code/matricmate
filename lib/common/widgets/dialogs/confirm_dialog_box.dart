import 'package:flutter/material.dart';

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
}
