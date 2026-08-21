import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matricmate/common/widgets/appbar/appbar.dart';
import 'package:matricmate/common/widgets/dialogs/confirm_dialog_box.dart';
import 'package:matricmate/common/widgets/loaders/circular_loading.dart';
import 'package:matricmate/features/exam/controllers/premium_controller.dart';
import 'package:matricmate/features/exam/screens/premium/widgets/telegram_chat.dart';
import 'package:matricmate/features/personalization/controllers/user_controller.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

class PaymentVerificationScreen extends StatelessWidget {
  const PaymentVerificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = PremiumController.instance;
    final userCtrl = UserController.instance;
    final isDark = AppHelperFunctions.isDark(context);

    final cardBg = isDark ? AppColors.darkSurface : AppColors.lightCard;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.borderPrimary;
    final primaryTextColor = isDark ? AppColors.textWhite : AppColors.textPrimary;
    final secondaryTextColor = isDark ? AppColors.darkGrey : AppColors.textSecondary;

    return Scaffold(
      appBar: Appbar(
        showBackArrow: true,
        title: Text(
          'Payment Status',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall!.apply(color: AppColors.white),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        child: Obx(() {
          final isFetching = userCtrl.userFetching.value;
          final isLoading = controller.isUploading.value;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 12),

              // ── Primary Theme Status Hero ─────────────────────────
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary,
                      AppColors.primary.withValues(alpha: 0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.35),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.hourglass_top_rounded,
                    color: AppColors.white,
                    size: 44,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ── Title & Subtitle ──────────────────────────────────
              Text(
                'Verification in Progress',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                  color: primaryTextColor,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                'Your payment receipt was received and is currently being verified by our team.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: secondaryTextColor,
                ),
              ),

              const SizedBox(height: 24),

              // ── Step Timeline Card ────────────────────────────────
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: borderColor),
                ),
                child: Column(
                  children: [
                    _timelineStep(
                      stepNumber: '1',
                      title: 'Receipt Submitted',
                      subtitle: 'Uploaded from your gallery',
                      isCompleted: true,
                      isActive: false,
                      isDark: isDark,
                    ),
                    _timelineDivider(isCompleted: true, isDark: isDark),
                    _timelineStep(
                      stepNumber: '2',
                      title: 'Admin Verification',
                      subtitle: 'Usually confirmed within 15–30 minutes',
                      isCompleted: false,
                      isActive: true,
                      isDark: isDark,
                    ),
                    _timelineDivider(isCompleted: false, isDark: isDark),
                    _timelineStep(
                      stepNumber: '3',
                      title: 'Instant Activation',
                      subtitle: 'All tests & explanations unlocked',
                      isCompleted: false,
                      isActive: false,
                      isDark: isDark,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── Action Buttons ────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: isFetching
                      ? null
                      : () async {
                          await userCtrl.checkPaymentStatus();
                        },
                  child: isFetching
                      ? const AppCircularButtonLoading()
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.refresh_rounded, size: 20, color: AppColors.white),
                            SizedBox(width: 8),
                            Text(
                              'Check Verification Status',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.white,
                              ),
                            ),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: () => Get.until((route) => route.isFirst),
                  icon: const Icon(Icons.home_outlined, size: 18),
                  label: const Text(
                    'Back to Home',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    side: BorderSide(color: borderColor),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // Cancel payment text link
              TextButton(
                onPressed: isLoading
                    ? null
                    : () {
                        AppDialogBoxes.showOkCancelDialog(
                          context: context,
                          title: 'Cancel Payment',
                          subtitle:
                              'Are you sure you want to cancel this pending payment?',
                          onPressed: () {
                            Get.back();
                            controller.cancelPayment();
                          },
                        );
                      },
                child: Text(
                  'Cancel This Submission',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.error.withValues(alpha: 0.9),
                  ),
                ),
              ),

              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),

              const TelegramChatButton(),
            ],
          );
        }),
      ),
    );
  }

  static Widget _timelineStep({
    required String stepNumber,
    required String title,
    required String subtitle,
    required bool isCompleted,
    required bool isActive,
    required bool isDark,
  }) {
    final Color badgeColor = isCompleted
        ? AppColors.success
        : (isActive ? AppColors.primary : (isDark ? AppColors.darkBorder : AppColors.grey));

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: badgeColor,
            shape: BoxShape.circle,
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.4),
                      blurRadius: 8,
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check, size: 16, color: AppColors.white)
                : Text(
                    stepNumber,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.white,
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.textWhite : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? AppColors.darkGrey : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static Widget _timelineDivider({required bool isCompleted, required bool isDark}) {
    return Container(
      margin: const EdgeInsets.only(left: 13, top: 4, bottom: 4),
      height: 20,
      width: 2,
      color: isCompleted
          ? AppColors.success
          : (isDark ? AppColors.darkBorder : AppColors.grey),
    );
  }
}
