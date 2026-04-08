import 'package:flutter/material.dart';

class AppHelperMethods {
  static void showImageZoom(
    BuildContext context,
    String imageUrl, {
    bool isAssetImage = false,
  }) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.all(0),
        child: InteractiveViewer(
          panEnabled: true,
          minScale: 1.0,
          maxScale: 4.0,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: isAssetImage
                ? Image.asset(imageUrl, fit: BoxFit.contain)
                : Image.network(imageUrl, fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }

  static void showExitDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit Quiz?'),
        content: const Text('Your progress will be saved.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Exit'),
          ),
        ],
      ),
    );
  }
}
