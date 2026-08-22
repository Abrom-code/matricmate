import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matricmate/common/widgets/loaders/circular_loading.dart';
import 'package:matricmate/features/authentication/controllers/login/login_controller.dart';
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
                    'Are you sure you want to log out of MatricMate?',
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

  /// Shows the device change confirmation dialog with modern styling.
  static Future<bool?> changeDevice(
    String email,
    LoginController ctrl,
    Future<void> Function() onConfirm,
  ) {
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
            child: Obx(
              () {
                final remainingTrials = ctrl.trials.value;
                final isExhausted = remainingTrials <= 0;

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── Dual-Ring Device Icon Badge ─────────────────────────
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: (isExhausted
                                ? const Color(0xFFEF4444)
                                : const Color(0xFFF59E0B))
                            .withValues(alpha: dark ? 0.14 : 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: (isExhausted
                                    ? const Color(0xFFEF4444)
                                    : const Color(0xFFF59E0B))
                                .withValues(alpha: dark ? 0.22 : 0.14),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Icon(
                              isExhausted
                                  ? Icons.phonelink_erase_rounded
                                  : Icons.devices_other_rounded,
                              color: isExhausted
                                  ? const Color(0xFFEF4444)
                                  : const Color(0xFFF59E0B),
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // ── Title ─────────────────────────────────────────────
                    Text(
                      isExhausted
                          ? 'Device Limit Reached'
                          : 'New Device Detected',
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
                      isExhausted
                          ? 'You have used all available device switches for this account.'
                          : 'This account is currently registered on another phone. Would you like to switch to this device?',
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

                    // ── Status / Warning Banner ───────────────────────────
                    if (!isExhausted) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B).withValues(
                            alpha: dark ? 0.12 : 0.08,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: const Color(0xFFF59E0B).withValues(
                              alpha: dark ? 0.30 : 0.20,
                            ),
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.info_outline_rounded,
                                  size: 16,
                                  color: Color(0xFFF59E0B),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Logging in here will sign out your previous phone.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: dark
                                          ? const Color(0xFFFCD34D)
                                          : const Color(0xFFB45309),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Switches remaining:',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: dark
                                        ? AppColors.darkGrey
                                        : AppColors.textSecondary,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withValues(
                                      alpha: dark ? 0.25 : 0.12,
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '$remainingTrials trial${remainingTrials == 1 ? '' : 's'}',
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      const TelegramChatButton(),
                    ],

                    const SizedBox(height: 22),

                    // ── Action Buttons ────────────────────────────────────
                    Row(
                      children: [
                        // Cancel / Close Button
                        Expanded(
                          child: SizedBox(
                            height: 46,
                            child: OutlinedButton(
                              onPressed: ctrl.isUpdating.value
                                  ? null
                                  : () => Get.back(result: false),
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
                                isExhausted ? 'Close' : 'Cancel',
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

                        if (!isExhausted) ...[
                          const SizedBox(width: 12),
                          // Switch Device Button
                          Expanded(
                            child: SizedBox(
                              height: 46,
                              child: ElevatedButton(
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
                                onPressed: ctrl.isUpdating.value
                                    ? null
                                    : () async {
                                        ctrl.isUpdating.value = true;
                                        try {
                                          await onConfirm();
                                          Get.back(result: true);
                                        } catch (e) {
                                          ctrl.isUpdating.value = false;
                                          Get.snackbar('Error', e.toString());
                                        }
                                      },
                                child: ctrl.isUpdating.value
                                    ? const AppCircularButtonLoading(
                                        color: Colors.white,
                                      )
                                    : const Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.swap_horiz_rounded,
                                            size: 18,
                                            color: Colors.white,
                                          ),
                                          SizedBox(width: 6),
                                          Text(
                                            'Switch Device',
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
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

