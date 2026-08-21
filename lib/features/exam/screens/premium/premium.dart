import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matricmate/common/widgets/appbar/appbar.dart';
import 'package:matricmate/common/widgets/loaders/circular_loading.dart';
import 'package:matricmate/data/services/payment_config_service.dart';
import 'package:matricmate/features/exam/controllers/premium_controller.dart';
import 'package:matricmate/features/exam/screens/premium/widgets/payment_tile.dart';
import 'package:matricmate/features/exam/screens/premium/widgets/plan_selector.dart';
import 'package:matricmate/features/personalization/controllers/user_controller.dart';
import 'package:matricmate/routes/app_routes.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

class PremiumScreen extends StatelessWidget {
  const PremiumScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = PremiumController.instance;
    final cfg = PaymentConfigService.instance;
    final isDark = AppHelperFunctions.isDark(context);

    return Scaffold(
      appBar: Appbar(
        showBackArrow: true,
        title: Text(
          'Upgrade to Premium',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall!.apply(color: AppColors.white),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, _) {
          final isLandscape =
              MediaQuery.orientationOf(context) == Orientation.landscape;

          final content = RefreshIndicator(
            onRefresh: () => controller.reloadPaymentConfig(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Obx(() {
                final selectedPlan = controller.selectedPlan.value;
                final price = controller.selectedPlanPrice;
                final methods = cfg.methods.toList();
                final selected = controller.selectedPayment.value;
                final isLoading = cfg.isLoading.value;
                final hasError = cfg.hasError.value;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Plan Duration Selector ─────────────────────
                    const PlanSelector(),

                    const SizedBox(height: 20),

                    // ── Selected Plan Hero Card ────────────────────
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF0D9488),
                            Color(0xFF0F766E),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0D9488).withValues(alpha: 0.35),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${selectedPlan.durationMonths} MONTHS ACCESS',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              if (selectedPlan.badgeText != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFF9500),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    selectedPlan.badgeText!,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${selectedPlan.title} Plan',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    selectedPlan.subtitle,
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.85),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: '$price',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 32,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: -0.8,
                                      ),
                                    ),
                                    const TextSpan(
                                      text: ' ETB',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── Payment Methods Header ─────────────────────
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
                            Icons.account_balance_wallet_rounded,
                            size: 16,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '2. SELECT PAYMENT METHOD',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                            color: isDark
                                ? const Color(0xFFA1A1AA)
                                : const Color(0xFF52525B),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // ── Payment Methods List ────────────────────────
                    if (isLoading && methods.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 32),
                        child: AppCircularLoading(
                          title: 'Loading payment options...',
                        ),
                      )
                    else if (hasError && methods.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF18181B)
                              : const Color(0xFFF4F4F5),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Center(
                          child: Column(
                            children: [
                              const Icon(
                                Icons.wifi_off_rounded,
                                size: 40,
                                color: AppColors.grey,
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                'Unable to load payment methods',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Please check your internet connection.',
                                style: TextStyle(
                                  color: AppColors.darkGrey,
                                  fontSize: 12,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 14),
                              OutlinedButton.icon(
                                onPressed: () =>
                                    controller.reloadPaymentConfig(),
                                icon: const Icon(Icons.refresh_rounded, size: 16),
                                label: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      )
                    else if (methods.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF18181B)
                              : const Color(0xFFF4F4F5),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Center(
                          child: Column(
                            children: [
                              const Icon(
                                Icons.account_balance_wallet_outlined,
                                size: 40,
                                color: AppColors.grey,
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                'Payment options updating',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Methods are currently being updated by admin.',
                                style: TextStyle(
                                  color: AppColors.darkGrey,
                                  fontSize: 12,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 14),
                              OutlinedButton.icon(
                                onPressed: () =>
                                    controller.reloadPaymentConfig(),
                                icon: const Icon(Icons.refresh_rounded, size: 16),
                                label: const Text('Refresh'),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ...methods.map((method) {
                        return paymentTile(
                          title: method.label,
                          subtitle: method.account.isNotEmpty
                              ? method.account.length < 15
                                    ? method.account
                                    : '${method.account.substring(0, 12)}...'
                              : '',
                          icon: method.icon,
                          isFeatured: method.isFeatured,
                          selected: selected == method,
                          context: context,
                          onTap: () =>
                              controller.selectedPayment.value = method,
                        );
                      }),
                  ],
                );
              }),
            ),
          );

          if (!isLandscape) return content;
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: content,
            ),
          );
        },
      ),
      bottomNavigationBar: Obx(() {
        final isPending = UserController.instance.user.value.isPending;
        final hasMethod = controller.selectedPayment.value != null;
        final price = controller.selectedPlanPrice;
        final selectedPlan = controller.selectedPlan.value;

        return Container(
          padding: EdgeInsets.fromLTRB(
            16,
            12,
            16,
            MediaQuery.paddingOf(context).bottom + 12,
          ),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF141416) : Colors.white,
            border: Border(
              top: BorderSide(
                color: isDark ? const Color(0xFF27272A) : const Color(0xFFE4E4E7),
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
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: (!isPending && !hasMethod)
                  ? null
                  : isPending
                  ? () => Get.toNamed(Routes.paymentVerification)
                  : () {
                      if (controller.exceededUploadLimit) {
                        Get.toNamed(Routes.contactAdmin);
                      } else {
                        Get.toNamed(
                          Routes.payment,
                          arguments: controller.selectedPayment.value,
                        );
                      }
                    },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isPending
                        ? 'Check Payment Status'
                        : 'Continue — $price ETB (${selectedPlan.title})',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    size: 18,
                    color: Colors.white,
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
