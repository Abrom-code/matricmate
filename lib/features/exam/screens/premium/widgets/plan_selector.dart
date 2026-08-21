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
                color: isDark ? AppColors.darkGrey : AppColors.textSecondary,
              ),
            ),
            const Spacer(),
            Text(
              'One-time payment',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: isDark ? AppColors.darkGrey : AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Horizontal scrollable list of plan cards
        SizedBox(
          height: 160,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
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
    final isFeatured = plan.isFeatured;

    final activeBorderColor = isFeatured
        ? (isSelected ? AppColors.primary : AppColors.amberAccent)
        : AppColors.primary;

    final inactiveBorderColor = isFeatured
        ? AppColors.amberAccent.withValues(alpha: 0.6)
        : (isDark ? AppColors.darkBorder : AppColors.borderPrimary);

    final cardBg = isSelected
        ? (isDark
            ? AppColors.primary.withValues(alpha: 0.15)
            : AppColors.primary.withValues(alpha: 0.08))
        : (isDark ? AppColors.darkCard : AppColors.white);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            width: 142,
            padding: const EdgeInsets.fromLTRB(14, 18, 14, 14),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? activeBorderColor : inactiveBorderColor,
                width: isSelected ? 2 : (isFeatured ? 1.5 : 1),
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: (isFeatured ? AppColors.amberAccent : AppColors.primary)
                            .withValues(alpha: 0.25),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : (isFeatured
                      ? [
                          BoxShadow(
                            color: AppColors.amberAccent.withValues(alpha: 0.12),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]),
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
                        color: isDark ? AppColors.textWhite : AppColors.textPrimary,
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
                                  ? AppColors.darkGrey
                                  : AppColors.grey),
                          width: 2,
                        ),
                      ),
                      child: isSelected
                          ? const Icon(
                              Icons.check,
                              size: 13,
                              color: AppColors.white,
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
                        ? AppColors.darkGrey
                        : AppColors.textSecondary,
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
                                      ? AppColors.primary.withValues(alpha: 0.9)
                                      : AppColors.primary)
                                  : (isDark
                                      ? AppColors.textWhite
                                      : AppColors.textPrimary),
                            ),
                          ),
                          TextSpan(
                            text: ' ETB',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? AppColors.darkGrey
                                  : AppColors.textSecondary,
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
                            ? AppColors.darkGrey
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Featured / Best Value Badge
        if (isFeatured || plan.badgeText != null)
          Positioned(
            top: -8,
            right: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFFF59E0B),
                    Color(0xFFD97706),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFD97706).withValues(alpha: 0.45),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.star_rounded,
                    size: 12,
                    color: AppColors.white,
                  ),
                  SizedBox(width: 3),
                  Text(
                    'BEST VALUE',
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
