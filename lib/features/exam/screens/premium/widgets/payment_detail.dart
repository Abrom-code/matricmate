import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:matricmate/data/services/payment_config_service.dart';
import 'package:matricmate/features/exam/controllers/premium_controller.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

class PaymentDetail extends StatefulWidget {
  const PaymentDetail({super.key, required this.payment});

  final PaymentConfig payment;

  @override
  State<PaymentDetail> createState() => _PaymentDetailState();
}

class _PaymentDetailState extends State<PaymentDetail> {
  bool _isCopying = false;
  bool _isCopied = false;

  Future<void> _handleCopy(String text) async {
    if (_isCopying) return;

    setState(() {
      _isCopying = true;
      _isCopied = false;
    });

    await Clipboard.setData(ClipboardData(text: text));

    // Show quick micro-loading feedback
    await Future.delayed(const Duration(milliseconds: 280));

    if (!mounted) return;
    setState(() {
      _isCopying = false;
      _isCopied = true;
    });

    // Reset copied state after 1.8s
    await Future.delayed(const Duration(milliseconds: 1800));
    if (mounted) {
      setState(() => _isCopied = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppHelperFunctions.isDark(context);
    final controller = PremiumController.instance;
    final activePayment = controller.selectedPayment.value ?? widget.payment;
    final number = activePayment.account.isNotEmpty
        ? activePayment.account
        : (PaymentConfigService.hardcodedAccounts[activePayment.key] ??
            widget.payment.account);
    final name = activePayment.holder;

    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(
            height: 1,
            color: isDark ? AppColors.darkBorder : AppColors.borderPrimary,
          ),
          const SizedBox(height: 12),
          // Amount callout
          Obx(() {
            final price = controller.selectedPlanPrice;
            final plan = controller.selectedPlan.value;
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Amount to Transfer:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.darkGrey : AppColors.textSecondary,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: isDark ? 0.25 : 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$price ETB (${plan.title})',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            );
          }),

          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // ── Account Number & Name Row with Animated Copy Button ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ACCOUNT NUMBER',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: isDark ? AppColors.darkGrey : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.credit_card_rounded,
                          size: 17,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: SelectableText(
                            number,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                              color: isDark ? AppColors.textWhite : AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (name.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.verified_user_rounded,
                            size: 17,
                            color: AppColors.success,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: SelectableText(
                              name,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.2,
                                color: isDark ? AppColors.textWhite : AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),

              // ── Animated Copy Button (Icon only) ──
              InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: _isCopying ? null : () => _handleCopy(number),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: _isCopied ? AppColors.success : AppColors.primary,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: (_isCopied ? AppColors.success : AppColors.primary)
                            .withValues(alpha: 0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: _isCopying
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.white,
                              ),
                            )
                          : Icon(
                              _isCopied
                                  ? Icons.check_rounded
                                  : Icons.copy_rounded,
                              key: ValueKey<bool>(_isCopied),
                              size: 18,
                              color: AppColors.white,
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
