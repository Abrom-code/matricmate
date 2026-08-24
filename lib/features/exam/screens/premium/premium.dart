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
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isDark
                              ? [
                                  const Color(0xFF064E3B),
                                  const Color(0xFF0F766E),
                                ]
                              : [
                                  const Color(0xFF047857),
                                  const Color(0xFF0D9488),
                                ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF047857).withValues(alpha: 0.25),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header Row: Access Chip + Tier Tag
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 9,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.workspace_premium_rounded,
                                      size: 13,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 4.5),
                                    Text(
                                      '${selectedPlan.durationMonths} MONTHS ACCESS',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (selectedPlan.isFeatured || selectedPlan.badgeText != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3.5,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFFF59E0B),
                                        Color(0xFFD97706),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFFD97706).withValues(alpha: 0.35),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.star_rounded,
                                        size: 11,
                                        color: Colors.white,
                                      ),
                                      SizedBox(width: 3),
                                      Text(
                                        'BEST VALUE',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 9,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              else
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3.5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'ONE-TIME PAYMENT',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.4,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Plan Name + Big Price
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${selectedPlan.title} Access',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 17,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      selectedPlan.subtitle.isNotEmpty
                                          ? selectedPlan.subtitle
                                          : 'All subjects, tests & explanations',
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.85),
                                        fontSize: 11.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: '$price',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 26,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: -0.6,
                                      ),
                                    ),
                                    const TextSpan(
                                      text: ' ETB',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),
                          Container(
                            height: 1,
                            color: Colors.white.withValues(alpha: 0.15),
                          ),
                          const SizedBox(height: 10),

                          // Micro Features Row
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _HeroPerkItem(
                                icon: Icons.check_circle_rounded,
                                label: 'All Grades (9-12)',
                              ),
                              _HeroPerkItem(
                                icon: Icons.offline_bolt_rounded,
                                label: '100% Offline',
                              ),
                              _HeroPerkItem(
                                icon: Icons.translate_rounded,
                                label: 'Amharic + Eng',
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
                                ? AppColors.darkGrey
                                : AppColors.textSecondary,
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
                              ? AppColors.darkSurface
                              : AppColors.lightCard,
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
                              ? AppColors.darkSurface
                              : AppColors.lightCard,
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
            color: isDark ? AppColors.darkCard : AppColors.white,
            border: Border(
              top: BorderSide(
                color: isDark ? AppColors.darkBorder : AppColors.borderPrimary,
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
                      color: AppColors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    size: 18,
                    color: AppColors.white,
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

class _HeroPerkItem extends StatelessWidget {
  const _HeroPerkItem({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12.5, color: const Color(0xFF6EE7B7)),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFFE6FFFA),
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
