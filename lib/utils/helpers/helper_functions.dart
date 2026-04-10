import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:matricmate/utils/constants/image_string.dart';

class AppHelperFuntions {
  static void showSnackBar(String message) {
    ScaffoldMessenger.of(
      Get.context!,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  static void showAlert(String title, String message) {
    showDialog(
      context: Get.context!,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

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

  static String truncateText(String text, int maxLen) {
    if (text.length <= maxLen) {
      return text;
    } else {
      return "${text.substring(0, maxLen)}...";
    }
  }

  static bool isDark(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }

  static Size screenSize() {
    return MediaQuery.of(Get.context!).size;
  }

  static double screenHeight() {
    return MediaQuery.of(Get.context!).size.height;
  }

  static double screenWidth() {
    return MediaQuery.of(Get.context!).size.width;
  }

  static String getFormattedDate(
    DateTime date, {
    String formate = 'dd MMM yyyy',
  }) {
    return DateFormat(formate).format(date);
  }

  static List<T> removeDuplicates<T>(List<T> list) {
    return list.toSet().toList();
  }

  static List<Widget> wrapWidgets(List<Widget> widgets, int rowSize) {
    final wrappedList = <Widget>[];
    for (var i = 0; i < widgets.length; i += rowSize) {
      final rowchildren = widgets.sublist(
        i,
        i + rowSize > widgets.length ? widgets.length : i + rowSize,
      );
      wrappedList.add(Row(children: rowchildren));
    }
    return wrappedList;
  }

  static String getSubjectImage(String subject) {
    switch (subject) {
      case "Biology":
        return AppImages.biology;
      case "Chemistry":
        return AppImages.chemistry;
      case "Physics":
        return AppImages.physics;
      case "Natural Maths" || "Social Maths":
        return AppImages.maths;
      case "History":
        return AppImages.history;
      case "Geography":
        return AppImages.geography;
      case "Economics":
        return AppImages.economics;
      case "English":
        return AppImages.english;
      case "SAT":
        return AppImages.sat;
      default:
        return AppImages.unknownBook;
    }
  }

  static String getChapterName(int n) {
    switch (n) {
      case 1:
        return "Chapter One";
      case 2:
        return "Chapter Two";
      case 3:
        return "Chapter Three";
      case 4:
        return "Chapter Four";
      case 5:
        return "Chapter Five";
      case 6:
        return "Chapter Six";
      case 7:
        return "Chapter Seven";
      case 8:
        return "Chapter Eight";
      case 9:
        return "Chapter Nine";
      case 10:
        return "Chapter Ten";
      case 11:
        return "Chapter Eleven";
      default:
        return "Opps..!";
    }
  }
}
