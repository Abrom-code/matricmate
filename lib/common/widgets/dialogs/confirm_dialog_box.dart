import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matricmate/features/exam/screens/premium/widgets/telegram_chat.dart';
import 'package:matricmate/features/personalization/controllers/user_controller.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

class AppDialogBoxes {
  /// Shows a dedicated, premium logout confirmation dialog with user context.
  static Future<bool?> showLogoutDialog({
    required BuildContext context,
    required VoidCallback onLogout,
    VoidCallback? onCancel,
  }) {
    final dark = AppHelperFunctions.isDark(context);
    String? userEmail;
    try {
      if (Get.isRegistered<UserController>()) {
        final email = UserController.instance.user.value.email;
        if (email.isNotEmpty) userEmail = email;
      }
    } catch (_) {}

    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: dark ? AppColors.darkCard : AppColors.white,
          elevation: 16,
          shadowColor: Colors.black.withValues(alpha: dark ? 0.5 : 0.15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(
              color: dark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
              width: 1.2,
            ),
          ),
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 28, 22, 22),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Layered Logout Icon Badge ─────────────────────────
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(
                        alpha: dark ? 0.14 : 0.08,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withValues(
                            alpha: dark ? 0.22 : 0.14,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.logout_rounded,
                            color: Color(0xFFEF4444),
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // ── Title ─────────────────────────────────────────────
                  Text(
                    'Log Out',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.4,
                      color: dark ? AppColors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // ── Subtitle ──────────────────────────────────────────
                  Text(
                    'Are you sure you want to log out of MatricET?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13.5,
                      height: 1.45,
                      color: dark ? AppColors.darkGrey : AppColors.textSecondary,
                    ),
                  ),

                  // ── User Account Chip ─────────────────────────────────
                  if (userEmail != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: dark
                            ? AppColors.darkSurface
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: dark
                              ? AppColors.darkInputBorder
                              : const Color(0xFFE2E8F0),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.account_circle_outlined,
                            size: 15,
                            color: dark
                                ? AppColors.darkInputLabel
                                : AppColors.lightInputLabel,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              userEmail,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: dark
                                    ? AppColors.white
                                    : const Color(0xFF334155),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // ── Action Buttons ────────────────────────────────────
                  Row(
                    children: [
                      // Cancel Button
                      Expanded(
                        child: SizedBox(
                          height: 46,
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.pop(dialogContext, false);
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

                      // Log Out Button
                      Expanded(
                        child: SizedBox(
                          height: 46,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(dialogContext, true);
                              onLogout();
                            },
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              backgroundColor: const Color(0xFFEF4444),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.logout_rounded,
                                  size: 16,
                                  color: Colors.white,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'Log Out',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    height: 1.0,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
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

  /// Shows a modern, beautifully styled confirmation dialog.
  static Future<bool?> showOkCancelDialog({
    required BuildContext context,
    String? title,
    String? subtitle,
    String? confirmText,
    String cancelText = 'Cancel',
    IconData? icon,
    Color? iconColor,
    Color? confirmButtonColor,
    bool isDestructive = false,
    required VoidCallback onPressed,
    VoidCallback? onCancel,
  }) {
    final dark = AppHelperFunctions.isDark(context);

    // Auto-detect destructive intent from title or flag
    final isLogout = title?.toLowerCase().contains('log out') ?? false;
    final isDelete = title?.toLowerCase().contains('delete') ?? false;
    final isCancelAction = title?.toLowerCase().contains('cancel') ?? false;
    final bool destructive =
        isDestructive || isLogout || isDelete || isCancelAction;

    final resolvedIcon = icon ??
        (isLogout
            ? Icons.logout_rounded
            : (isDelete
                ? Icons.delete_forever_rounded
                : (isCancelAction
                    ? Icons.cancel_outlined
                    : Icons.help_outline_rounded)));

    final resolvedIconColor = iconColor ??
        (destructive
            ? const Color(0xFFEF4444)
            : AppColors.primary);

    final resolvedConfirmText = confirmText ??
        (isLogout
            ? 'Log Out'
            : (isDelete
                ? 'Delete'
                : (isCancelAction ? 'Confirm' : 'OK')));

    final resolvedConfirmColor = confirmButtonColor ??
        (destructive ? const Color(0xFFEF4444) : AppColors.primary);

    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
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
                  // ── Icon Badge ──────────────────────────────
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: resolvedIconColor.withValues(
                        alpha: dark ? 0.20 : 0.10,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(
                        resolvedIcon,
                        color: resolvedIconColor,
                        size: 26,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Title ───────────────────────────────────
                  Text(
                    title ?? 'Confirm Action',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                      color: dark ? AppColors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // ── Subtitle ────────────────────────────────
                  Text(
                    subtitle ?? 'Are you sure you want to proceed?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13.5,
                      height: 1.45,
                      color: dark ? AppColors.darkGrey : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Action Buttons ──────────────────────────
                  Row(
                    children: [
                      // Cancel Button
                      Expanded(
                        child: SizedBox(
                          height: 44,
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.pop(dialogContext, false);
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
                              cancelText,
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

                      // Confirm / Action Button
                      Expanded(
                        child: SizedBox(
                          height: 44,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(dialogContext, true);
                              onPressed();
                            },
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              backgroundColor: resolvedConfirmColor,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              resolvedConfirmText,
                              style: const TextStyle(
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

  /// Shows the device locked dialog informing the user their account is bound to another phone.
  static Future<bool?> deviceLocked(String email) {
    final context = Get.context;
    final dark = context != null ? AppHelperFunctions.isDark(context) : true;

    return Get.dialog<bool>(
      Dialog(
        backgroundColor: dark ? AppColors.darkCard : AppColors.white,
        elevation: 16,
        shadowColor: Colors.black.withValues(alpha: dark ? 0.5 : 0.15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: dark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
            width: 1.2,
          ),
        ),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 390),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 28, 22, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Dual-Ring Device Icon Badge ─────────────────────────
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withValues(alpha: dark ? 0.14 : 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withValues(alpha: dark ? 0.22 : 0.14),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.phonelink_lock_rounded,
                          color: Color(0xFFEF4444),
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // ── Title ─────────────────────────────────────────────
                Text(
                  'Account Locked to Device',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.4,
                    color: dark ? AppColors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 8),

                // ── Subtitle ──────────────────────────────────────────
                Text(
                  'This account is registered on another phone. Each subscription is valid for strictly one device. If you lost or changed your phone, please contact support on Telegram to request a device transfer.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.45,
                    color: dark ? AppColors.darkGrey : AppColors.textSecondary,
                  ),
                ),

                // ── Account Email Chip ────────────────────────────────
                if (email.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: dark
                          ? AppColors.darkSurface
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: dark
                            ? AppColors.darkInputBorder
                            : const Color(0xFFE2E8F0),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.alternate_email_rounded,
                          size: 14,
                          color: dark
                              ? AppColors.darkInputLabel
                              : AppColors.lightInputLabel,
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            email,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: dark
                                  ? AppColors.white
                                  : const Color(0xFF334155),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 16),
                const TelegramChatButton(),
                const SizedBox(height: 18),

                // ── Close Button ────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: OutlinedButton(
                    onPressed: () => Get.back(result: false),
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
                      'Close',
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Shows a dialog informing the user that their app is on the latest version.
  static Future<void> showUpToDateDialog({
    required BuildContext context,
    required String currentVersion,
    required String buildNumber,
  }) {
    final dark = AppHelperFunctions.isDark(context);

    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: dark ? AppColors.darkCard : AppColors.white,
          elevation: 16,
          shadowColor: Colors.black.withValues(alpha: dark ? 0.5 : 0.15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(
              color: dark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
              width: 1.2,
            ),
          ),
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icon Badge
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(
                          alpha: dark ? 0.18 : 0.10,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(
                              alpha: dark ? 0.25 : 0.16,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.success,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Title
                    Text(
                      "You're Up to Date!",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                        color: dark ? AppColors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Subtitle (shorter per user request)
                    Text(
                      "You're using the latest version of MatricET.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.4,
                        color: dark ? AppColors.darkGrey : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Version Pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: dark
                            ? Colors.white.withValues(alpha: 0.05)
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: dark
                              ? AppColors.darkBorder
                              : const Color(0xFFE2E8F0),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.verified_rounded,
                            size: 14,
                            color: AppColors.success,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Version $currentVersion (Build $buildNumber)',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: dark
                                  ? AppColors.white
                                  : const Color(0xFF334155),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Action Button
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Great',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Shows a dialog informing the user that a new version of the app is available.
  static Future<void> showUpdateAvailableDialog({
    required BuildContext context,
    required String currentVersion,
    required String latestVersion,
    String? releaseNotes,
    required VoidCallback onUpdate,
  }) {
    final dark = AppHelperFunctions.isDark(context);

    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return Dialog(
          backgroundColor: dark ? AppColors.darkCard : AppColors.white,
          elevation: 16,
          shadowColor: Colors.black.withValues(alpha: dark ? 0.5 : 0.15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(
              color: dark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
              width: 1.2,
            ),
          ),
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icon Badge
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(
                          alpha: dark ? 0.20 : 0.12,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(
                              alpha: dark ? 0.30 : 0.18,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.system_update_rounded,
                            color: AppColors.primary,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Title
                    Text(
                      'New Version Available!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                        color: dark ? AppColors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Version comparison pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'v$currentVersion',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: dark
                                  ? AppColors.darkGrey
                                  : AppColors.textSecondary,
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 6),
                            child: Icon(
                              Icons.arrow_forward_rounded,
                              size: 13,
                              color: AppColors.primary,
                            ),
                          ),
                          Text(
                            'v$latestVersion',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    if (releaseNotes != null && releaseNotes.isNotEmpty) ...[
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "WHAT'S NEW",
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: dark
                                ? AppColors.darkGrey
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: double.infinity,
                        constraints: const BoxConstraints(maxHeight: 120),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: dark
                              ? Colors.white.withValues(alpha: 0.04)
                              : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: dark
                              ? AppColors.darkBorder
                              : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: SingleChildScrollView(
                          child: Text(
                            releaseNotes,
                            style: TextStyle(
                              fontSize: 12,
                              height: 1.45,
                              color: dark
                                  ? AppColors.white
                                  : const Color(0xFF334155),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ] else ...[
                      Text(
                        'A new update is available with improvements, question additions, and bug fixes.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12.5,
                          height: 1.4,
                          color: dark
                              ? AppColors.darkGrey
                              : AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 44,
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(dialogContext),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                  color: dark
                                      ? AppColors.darkInputBorder
                                      : const Color(0xFFCBD5E1),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'Later',
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                  color: dark
                                      ? AppColors.white
                                      : const Color(0xFF334155),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SizedBox(
                            height: 44,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pop(dialogContext);
                                onUpdate();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.download_rounded, size: 16),
                                  SizedBox(width: 6),
                                  Text(
                                    'Update',
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
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
          ),
        );
      },
    );
  }
}

