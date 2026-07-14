import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matricmate/routes/app_routes.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

class PendingPaymentBanner extends StatelessWidget {
  const PendingPaymentBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = AppHelperFunctions.isDark(context);

    final bg = dark ? const Color(0xFF1C1C1E) : const Color(0xFFF2F2F7);
    final borderColor = dark
        ? const Color(0xFF2C2C2E)
        : const Color(0xFFD1D1D6);
    final titleColor = dark ? Colors.white : const Color(0xFF1C1C1E);
    final subtitleColor = dark
        ? const Color(0xFF8E8E93)
        : const Color(0xFF6C6C70);
    final iconBg = dark
        ? const Color(0xFF2C2C2E)
        : const Color(0xFFE5E5EA);

    return GestureDetector(
      onTap: () => Get.toNamed(Routes.paymentVerification),
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 1),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // Status dot + icon
            Stack(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.receipt_long_rounded,
                    color: dark
                        ? const Color(0xFF8E8E93)
                        : const Color(0xFF6C6C70),
                    size: 20,
                  ),
                ),
                // Amber status dot
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF9F0A),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: bg,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(width: 14),

            // Copy
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Payment Pending',
                    style: TextStyle(
                      color: titleColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Verifying your receipt',
                    style: TextStyle(
                      color: subtitleColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),

            // Check status chip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: dark
                    ? const Color(0xFF2C2C2E)
                    : const Color(0xFFE5E5EA),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Check',
                    style: TextStyle(
                      color: dark ? Colors.white : const Color(0xFF1C1C1E),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 10,
                    color: dark ? Colors.white : const Color(0xFF1C1C1E),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
