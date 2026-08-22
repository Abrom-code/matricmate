import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/constants/app_images.dart';
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
    // Download images concurrently; individual failures are ignored
    await Future.wait(
      urls.map((url) async {
        try {
          await cache.downloadFile(url);
        } catch (e) {
          debugPrint('Image download failed for $url: $e');
        }
      }),
    );
  }

  static Future<void> removeCachedImages(Set<String> urls) async {
    if (urls.isEmpty) return;
    final cache = DefaultCacheManager();
    await Future.wait(
      urls.map((url) async {
        try {
          await cache.removeFile(url);
        } catch (e) {
          debugPrint('Image cache eviction failed for $url: $e');
        }
      }),
    );
  }

  static Future<void> showImageZoom(
    BuildContext context,
    String imageUrl, {
    bool isAssetImage = false,
    File? cachedFile,
  }) {
    return Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        pageBuilder: (context, _, __) {
          return Scaffold(
            backgroundColor: AppColors.black,
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
                            : cachedFile != null
                            ? Image.file(cachedFile, fit: BoxFit.contain)
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
                          color: AppColors.white,
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
    VoidCallback onOkPressed, {
    VoidCallback? onCancel,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final dark = isDark(context);
        return Dialog(
          backgroundColor: dark ? AppColors.darkCard : AppColors.white,
          elevation: 12,
          shadowColor: Colors.black.withValues(alpha: dark ? 0.4 : 0.12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: dark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
              width: 1.2,
            ),
          ),
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Icon ─────────────────────────────────────────────
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(
                        alpha: dark ? 0.20 : 0.12,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.pause_rounded,
                        color: AppColors.secondary,
                        size: 26,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Title ───────────────────────────────────────────
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                      color: dark ? AppColors.white : const Color(0xFF0F172A),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),

                  // ── Message ─────────────────────────────────────────
                  Text(
                    message,
                    style: TextStyle(
                      fontSize: 13.5,
                      height: 1.45,
                      color: dark ? AppColors.darkGrey : AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  // ── Actions ─────────────────────────────────────────
                  Row(
                    children: [
                      // Secondary button (Cancel)
                      Expanded(
                        child: SizedBox(
                          height: 44,
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              onCancel?.call();
                            },
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              side: BorderSide(
                                color: dark
                                    ? AppColors.darkInputBorder
                                    : const Color(0xFFCBD5E1),
                                width: 1.2,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                height: 1.0,
                                color: dark
                                    ? AppColors.white
                                    : const Color(0xFF334155),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Primary button (Ok / Resume)
                      Expanded(
                        child: SizedBox(
                          height: 44,
                          child: ElevatedButton(
                            onPressed: onOkPressed,
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'OK',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                height: 1.0,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
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
