import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matricmate/data/services/payment_config_service.dart';
import 'package:matricmate/features/exam/controllers/premium_controller.dart';
import 'package:matricmate/features/exam/models/subscription_plan.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

class PlanSelector extends StatelessWidget {
  const PlanSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = PremiumController.instance;
    final cfg = PaymentConfigService.instance;
    final isDark = AppHelperFunctions.isDark(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: isDark ? 0.2 : 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.calendar_month_rounded,
                size: 16,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '1. CHOOSE DURATION',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
                color: isDark ? const Color(0xFFA1A1AA) : const Color(0xFF52525B),
              ),
            ),
            const Spacer(),
            Text(
              'One-time payment',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: isDark ? const Color(0xFF71717A) : const Color(0xFFA1A1AA),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Horizontal scrollable list of plan cards
        SizedBox(
          height: 154,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
            itemCount: SubscriptionPlan.all.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final plan = SubscriptionPlan.all[index];
              return Obx(() {
                final isSelected = controller.selectedPlan.value == plan;
                final price = cfg.getPriceForPlan(plan.key, plan.defaultPrice);
                final monthlyPrice = (price / plan.durationMonths).round();

                return _ModernPlanCard(
                  plan: plan,
                  price: price,
                  monthlyPrice: monthlyPrice,
                  isSelected: isSelected,
                  isDark: isDark,
                  onTap: () => controller.selectedPlan.value = plan,
                );
              });
            },
          ),
        ),
      ],
    );
  }
}

class _ModernPlanCard extends StatelessWidget {
  const _ModernPlanCard({
    required this.plan,
    required this.price,
    required this.monthlyPrice,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  final SubscriptionPlan plan;
  final int price;
  final int monthlyPrice;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final activeBorderColor = AppColors.primary;
    final inactiveBorderColor = isDark
        ? const Color(0xFF27272A)
        : const Color(0xFFE4E4E7);

    final cardBg = isSelected
        ? (isDark
            ? const Color(0xFF1E2922)
            : const Color(0xFFF0FDF4))
        : (isDark ? const Color(0xFF18181B) : Colors.white);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            width: 140,
            padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? activeBorderColor : inactiveBorderColor,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.22),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Header: Title + Radio
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      plan.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                        color: isDark ? Colors.white : const Color(0xFF09090B),
                      ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected
                            ? AppColors.primary
                            : Colors.transparent,
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : (isDark
                                  ? const Color(0xFF52525B)
                                  : const Color(0xFFD4D4D8)),
                          width: 2,
                        ),
                      ),
                      child: isSelected
                          ? const Icon(
                              Icons.check,
                              size: 13,
                              color: Colors.white,
                            )
                          : null,
                    ),
                  ],
                ),

                // Subtitle (e.g. "Full exam prep")
                Text(
                  plan.subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? const Color(0xFFA1A1AA)
                        : const Color(0xFF71717A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                const Divider(height: 12, thickness: 0.5),

                // Price and monthly calculation
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '$price',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                              color: isSelected
                                  ? (isDark
                                      ? const Color(0xFF34D399)
                                      : AppColors.primary)
                                  : (isDark
                                      ? Colors.white
                                      : const Color(0xFF09090B)),
                            ),
                          ),
                          TextSpan(
                            text: ' ETB',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? const Color(0xFFA1A1AA)
                                  : const Color(0xFF71717A),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '~$monthlyPrice ETB / mo',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? const Color(0xFF71717A)
                            : const Color(0xFFA1A1AA),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Featured / Value Badge
        if (plan.badgeText != null)
          Positioned(
            top: -7,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF9500), Color(0xFFFF3B30)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF5E00).withValues(alpha: 0.4),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                plan.badgeText!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
