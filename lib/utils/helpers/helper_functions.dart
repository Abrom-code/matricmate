import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:matricmate/utils/constants/image_string.dart';
import 'package:url_launcher/url_launcher.dart';

class AppHelperFunctions {
  static Future<void> openUrl(String url) async {
    final Uri uri = Uri.parse(url);

    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('$url open failed: $e');
    }
  }

  static Future<void> downloadImages(Set<String> urls) async {
    if (urls.isEmpty) return;
    final cache = DefaultCacheManager();
    // Download all images concurrently instead of one by one
    await Future.wait(
      urls.map((url) => cache.downloadFile(url).catchError((e) => throw e)),
    );
  }

  static Future<void> showImageZoom(
    BuildContext context,
    String imageUrl, {
    bool isAssetImage = false,
  }) {
    return Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        pageBuilder: (context, _, __) {
          return Scaffold(
            backgroundColor: Colors.black,
            body: SizedBox.expand(
              child: Stack(
                children: [
                  // 🔥 FULL SCREEN INTERACTIVE VIEW
                  Positioned.fill(
                    child: InteractiveViewer(
                      panEnabled: true,
                      minScale: 1.0,
                      maxScale: 5.0,
                      child: Center(
                        child: isAssetImage
                            ? Image.asset(imageUrl, fit: BoxFit.contain)
                            : Image.network(imageUrl, fit: BoxFit.contain),
                      ),
                    ),
                  ),

                  // CLOSE BUTTON
                  Positioned(
                    top: 40,
                    right: 20,
                    child: SafeArea(
                      child: IconButton(
                        icon: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 30,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        transitionsBuilder: (context, animation, _, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  static void showAppDialog(
    BuildContext context,
    String title,
    String message,
    VoidCallback onOkPressed,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(onPressed: onOkPressed, child: const Text('Ok')),
        ],
      ),
    );
  }

  static String truncateText(String text, int maxLen) {
    if (text.length <= maxLen) {
      return text;
    } else {
      return '${text.substring(0, maxLen)}...';
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

  static String getSubjectImage(String subject) {
    switch (subject) {
      case 'Biology':
        return AppImages.biology;
      case 'Chemistry':
        return AppImages.chemistry;
      case 'Physics':
        return AppImages.physics;
      case 'Natural Maths' || 'Social Maths':
        return AppImages.maths;
      case 'History':
        return AppImages.history;
      case 'Geography':
        return AppImages.geography;
      case 'Economics':
        return AppImages.economics;
      case 'English':
        return AppImages.english;
      case 'SAT':
        return AppImages.sat;
      default:
        return AppImages.unknownBook;
    }
  }

  static String getChapterName(int n) {
    switch (n) {
      case 1:
        return 'Unit One';
      case 2:
        return 'Unit Two';
      case 3:
        return 'Unit Three';
      case 4:
        return 'Unit Four';
      case 5:
        return 'Unit Five';
      case 6:
        return 'Unit Six';
      case 7:
        return 'Unit Seven';
      case 8:
        return 'Unit Eight';
      case 9:
        return 'Unit Nine';
      case 10:
        return 'Unit Ten';
      case 11:
        return 'Unit Eleven';
      default:
        return 'Opps..!';
    }
  }
}
