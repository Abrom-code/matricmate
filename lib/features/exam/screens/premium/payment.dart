import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matricmate/common/widgets/appbar/appbar.dart';
import 'package:matricmate/common/widgets/loaders/circular_loading.dart';
import 'package:matricmate/data/services/payment_config_service.dart';
import 'package:matricmate/features/exam/controllers/premium_controller.dart';
import 'package:matricmate/features/exam/screens/premium/widgets/link_input_field.dart';
import 'package:matricmate/features/exam/screens/premium/widgets/payment_detail.dart';
import 'package:matricmate/features/exam/screens/premium/widgets/payment_tile.dart';
import 'package:matricmate/features/exam/screens/premium/widgets/receipt_container.dart';
import 'package:matricmate/features/exam/screens/premium/widgets/telegram_chat.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

class PaymentScreen extends StatelessWidget {
  final PaymentConfig payment;
  const PaymentScreen({super.key, required this.payment});

  @override
  Widget build(BuildContext context) {
    final isDark = AppHelperFunctions.isDark(context);
    final controller = Get.find<PremiumController>();

    return Scaffold(
      appBar: Appbar(
        showBackArrow: true,
        title: Text(
          'Complete Payment',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall!.apply(color: AppColors.white),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Step Indicator ─────────────────────────────────────
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(
                      alpha: isDark ? 0.2 : 0.1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.send_to_mobile_rounded,
                    size: 16,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'TRANSFER INSTRUCTIONS',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: isDark
                        ? AppColors.darkGrey
                        : AppColors.textSecondary,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => Get.back(),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                  ),
                  child: const Text(
                    'Change Method',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // ── Payment Tile with Embedded Detail ──────────────────
            paymentTile(
              title: payment.label,
              subtitle: payment.account.isNotEmpty
                  ? payment.account.length < 15
                        ? payment.account
                        : '${payment.account.substring(0, 12)}...'
                  : '',
              icon: payment.icon,
              context: context,
              showIcon: false,
              isFeatured: payment.isFeatured,
              detail: PaymentDetail(payment: payment),
            ),

            const SizedBox(height: 20),

            // ── Verification Section ───────────────────────────────
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(
                      alpha: isDark ? 0.2 : 0.1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.receipt_long_rounded,
                    size: 16,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'PROOF OF PAYMENT',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: isDark
                        ? AppColors.darkGrey
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // ── Upload Form ────────────────────────────────────────
            Form(
              key: controller.paymentFormKey,
              child: Column(
                children: [
                  const LinkInputField(),
                  const SizedBox(height: 16),
                  Obx(() {
                    final file = controller.receipt.value;
                    return GestureDetector(
                      onTap: () => controller.pickReceipt(),
                      child: ReceiptContainer(file: file),
                    );
                  }),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Support ────────────────────────────────────
            const TelegramChatButton(),
          ],
        ),
      ),
      bottomNavigationBar: Obx(() {
        final isLoading = controller.isUploading.value;
        final hasReceipt = controller.receipt.value != null;
        final price = controller.selectedPlanPrice;

        return Container(
          padding: EdgeInsets.fromLTRB(
            16,
            12,
            16,
            MediaQuery.paddingOf(context).bottom + 12,
          ),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.white,
            border: Border(
              top: BorderSide(
                color: isDark
                    ? AppColors.darkBorder
                    : AppColors.borderPrimary,
              ),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                blurRadius: 10,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SizedBox(
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
              onPressed: isLoading ? null : () => controller.completePayment(),
              child: isLoading
                  ? const AppCircularButtonLoading()
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.check_circle_outline_rounded,
                          size: 20,
                          color: AppColors.white,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          hasReceipt
                              ? 'Submit Receipt ($price ETB)'
                              : 'Upload Receipt to Submit ($price ETB)',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.white,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        );
      }),
    );
  }
}
