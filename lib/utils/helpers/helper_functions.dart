import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:matricmate/utils/constants/app_strings.dart';
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
}
