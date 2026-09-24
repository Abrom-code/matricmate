import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matricmate/features/challenges/constants/challenge_colors.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

/// A premium, reusable full-screen downloading progress dialog with cancellation support.
/// Can be used across notes, subjects, exam downloads, and any batch background operations.
class DownloadProgressDialog extends StatelessWidget {
  const DownloadProgressDialog({
    super.key,
    required this.title,
    required this.progress,
    this.currentItem,
    this.completedCount,
    this.totalCount,
    this.subtitle,
    required this.onCancel,
    this.accentColor = ChallengeColors.accent,
  });

  final String title;
  final RxDouble progress;
  final RxString? currentItem;
  final RxInt? completedCount;
  final int? totalCount;
  final String? subtitle;
  final VoidCallback onCancel;
  final Color accentColor;

  static bool _isOpen = false;

  /// Returns true if the download progress dialog is currently presented.
  static bool get isOpen => _isOpen;

  /// Shows the reusable full screen download progress dialog.
  static void show({
    required String title,
    required RxDouble progress,
    RxString? currentItem,
    RxInt? completedCount,
    int? totalCount,
    String? subtitle,
    required VoidCallback onCancel,
    Color accentColor = ChallengeColors.accent,
  }) {
    if (_isOpen) return;

    final context = Get.overlayContext ?? Get.context;
    if (context == null) return;

    _isOpen = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (dialogCtx) => PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) return;
          // Prompt or directly trigger cancel on hardware back button
          onCancel();
        },
        child: DownloadProgressDialog(
          title: title,
          progress: progress,
          currentItem: currentItem,
          completedCount: completedCount,
          totalCount: totalCount,
          subtitle: subtitle,
          onCancel: onCancel,
          accentColor: accentColor,
        ),
      ),
    ).then((_) {
      _isOpen = false;
    });
  }

  /// Closes the download dialog if currently presented.
  static void hide() {
    if (!_isOpen) {
      try {
        if (Get.isDialogOpen ?? false) {
          Get.back();
        }
      } catch (_) {}
      return;
    }

    _isOpen = false;

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

  @override
  Widget build(BuildContext context) {
    final dark = AppHelperFunctions.isDark(context);

    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: dark ? 0.78 : 0.60),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Container(
              decoration: BoxDecoration(
                color: dark ? AppColors.darkCard : AppColors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: dark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: dark ? 0.45 : 0.15),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
              child: Obx(() {
                final currentProgress = progress.value.clamp(0.0, 1.0);
                final percentText = '${(currentProgress * 100).toInt()}%';
                final currentItemText = currentItem?.value ?? '';
                final currentCount = completedCount?.value ?? 0;

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── Animated Download Icon Badge ──────────────────────
                    Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            accentColor.withValues(alpha: dark ? 0.25 : 0.15),
                            accentColor.withValues(alpha: dark ? 0.10 : 0.05),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: accentColor.withValues(alpha: 0.35),
                          width: 1.5,
                        ),
                      ),
                      child: Center(
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: accentColor,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: accentColor.withValues(alpha: 0.35),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.download_rounded,
                              color: Colors.white,
                              size: 26,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Title ─────────────────────────────────────────────
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: dark ? AppColors.white : AppColors.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // ── Subtitle / Info ───────────────────────────────────
                    if (subtitle != null) ...[
                      Text(
                        subtitle!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: dark
                              ? AppColors.darkGrey
                              : AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 6),
                    ],

                    // ── Item Counter / Current Item Name ──────────────────
                    if (totalCount != null && totalCount! > 0) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Downloading ${(currentCount + 1).clamp(1, totalCount!)} of $totalCount',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: accentColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],

                    if (currentItemText.isNotEmpty) ...[
                      Text(
                        currentItemText,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: dark ? AppColors.textWhite : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 14),
                    ] else
                      const SizedBox(height: 10),

                    // ── Percentage Display ────────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          'Progress',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: dark
                                ? AppColors.darkGrey
                                : AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          percentText,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: accentColor,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // ── Linear Progress Bar ───────────────────────────────
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: currentProgress > 0 ? currentProgress : null,
                        minHeight: 8,
                        backgroundColor: dark
                            ? AppColors.darkSurface
                            : const Color(0xFFE2E8F0),
                        valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── Cancel Button ─────────────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: BorderSide(
                            color: AppColors.error.withValues(alpha: 0.5),
                            width: 1.2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: onCancel,
                        icon: const Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: AppColors.error,
                        ),
                        label: const Text(
                          'Cancel Download',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.error,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
