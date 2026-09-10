import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matricmate/common/widgets/loaders/circular_loading.dart';
import 'package:matricmate/features/authentication/controllers/login/verify_reset_otp_controller.dart';
import 'package:matricmate/features/authentication/screens/password_configuration/widgets/otp_input_widget.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

class VerifyResetOtpScreen extends GetView<VerifyResetOtpController> {
  const VerifyResetOtpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = AppHelperFunctions.isDark(context);

    return Scaffold(
      backgroundColor: dark ? AppColors.dark : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 19,
            color: dark ? AppColors.white : const Color(0xFF0F172A),
          ),
          onPressed: () => Get.back(),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          20,
          8,
          20,
          MediaQuery.paddingOf(context).bottom + 24,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon Badge
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.mark_email_read_rounded,
                color: AppColors.primary,
                size: 26,
              ),
            ),
            const SizedBox(height: 18),

            // Title
            Text(
              'Enter Verification Code',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
                color: dark ? AppColors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),

            // Subtitle with masked email
            Obx(
              () => RichText(
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.5,
                    color: dark ? AppColors.darkGrey : AppColors.textSecondary,
                  ),
                  children: [
                    const TextSpan(
                      text: "We've sent a 6-digit recovery code to ",
                    ),
                    TextSpan(
                      text: controller.maskedEmail.isNotEmpty
                          ? controller.maskedEmail
                          : 'your email',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: dark ? AppColors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const TextSpan(
                      text: '. Enter the code below to reset your password.',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),

            // OTP Input Card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              decoration: BoxDecoration(
                color: dark ? AppColors.darkCard : AppColors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: dark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: dark ? 0.2 : 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  OtpInputWidget(controller: controller),
                  const SizedBox(height: 24),

                  // Resend Section
                  Obx(() {
                    if (controller.isResending.value) {
                      return const Center(
                        child: AppCircularButtonLoading(color: AppColors.primary),
                      );
                    }

                    final cooldown = controller.resendCooldown.value;
                    if (cooldown > 0) {
                      final formattedSec =
                          cooldown < 10 ? '0$cooldown' : '$cooldown';
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.timer_outlined,
                            size: 16,
                            color: dark ? AppColors.darkGrey : AppColors.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "Didn't receive the code? Resend in 00:$formattedSec",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: dark
                                  ? AppColors.darkGrey
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      );
                    }

                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Didn't receive the code? ",
                          style: TextStyle(
                            fontSize: 13,
                            color: dark
                                ? AppColors.darkGrey
                                : AppColors.textSecondary,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => controller.resendOtp(),
                          child: const Text(
                            'Resend Code',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Verify Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: Obx(
                () => ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: controller.isVerifying.value
                      ? null
                      : () => controller.verifyOtp(),
                  child: controller.isVerifying.value
                      ? const AppCircularButtonLoading(color: Colors.white)
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Verify Code',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(Icons.arrow_forward_rounded, size: 18),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
