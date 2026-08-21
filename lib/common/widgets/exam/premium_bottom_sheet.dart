import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matricmate/data/services/payment_config_service.dart';
import 'package:matricmate/routes/app_routes.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

class PremiumBottomSheet extends StatelessWidget {
  const PremiumBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = AppHelperFunctions.isDark(context);
    final screenHeight = MediaQuery.sizeOf(context).height;
    final cfg = PaymentConfigService.instance;

    final bgColor = dark ? const Color(0xFF141416) : Colors.white;
    final cardBg = dark ? const Color(0xFF1E1E22) : const Color(0xFFF6F7FB);
    final borderColor = dark ? const Color(0xFF2C2C32) : const Color(0xFFE8ECF4);
    final primaryTextColor = dark ? Colors.white : const Color(0xFF1A1D1E);
    final secondaryTextColor = dark ? const Color(0xFF9E9EA7) : const Color(0xFF6C727A);

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: screenHeight * 0.90),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          color: bgColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 24,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Drag Handle ──────────────────────────────────────────
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: dark ? const Color(0xFF383840) : const Color(0xFFD5D8E2),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Scrollable Body ──────────────────────────────────────
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  20,
                  0,
                  20,
                  MediaQuery.paddingOf(context).bottom + 20,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── Floating Crown Icon ─────────────────────────
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFB800), Color(0xFFFF5E00)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF8A00).withValues(alpha: 0.35),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.workspace_premium_rounded,
                          color: Colors.white,
                          size: 34,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ── Title & Subtitle ────────────────────────────
                    Text(
                      'Unlock Full Access',
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
                      'Ace your matric exams with full entrance papers, chapter tests & Amharic explanations.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: secondaryTextColor,
                      ),
                    ),

                    const SizedBox(height: 22),

                    // ── Feature Rows ────────────────────────────────
                    _featureCard(
                      icon: Icons.military_tech_rounded,
                      iconGradient: const [Color(0xFFFF9500), Color(0xFFFF5E00)],
                      title: 'All Entrance & Model Exams',
                      subtitle: 'Access 10+ years of national matric & model questions.',
                      cardBg: cardBg,
                      borderColor: borderColor,
                      primaryText: primaryTextColor,
                      secondaryText: secondaryTextColor,
                    ),

                    _featureCard(
                      icon: Icons.menu_book_rounded,
                      iconGradient: const [Color(0xFF007AFF), Color(0xFF00C6FF)],
                      title: 'Complete Chapter Tests',
                      subtitle: 'Master every unit in Grades 9–12 with targeted quizzes.',
                      cardBg: cardBg,
                      borderColor: borderColor,
                      primaryText: primaryTextColor,
                      secondaryText: secondaryTextColor,
                    ),

                    _featureCard(
                      icon: Icons.translate_rounded,
                      iconGradient: const [Color(0xFF34C759), Color(0xFF30B0C7)],
                      title: 'Amharic & English Explanations',
                      subtitle: 'Detailed bilingual reasoning for every single question.',
                      cardBg: cardBg,
                      borderColor: borderColor,
                      primaryText: primaryTextColor,
                      secondaryText: secondaryTextColor,
                    ),

                    _featureCard(
                      icon: Icons.timer_outlined,
                      iconGradient: const [Color(0xFFAF52DE), Color(0xFFFF2D55)],
                      title: 'Timed Exam Simulation',
                      subtitle: 'Real exam clock, instant scores & bookmark review.',
                      cardBg: cardBg,
                      borderColor: borderColor,
                      primaryText: primaryTextColor,
                      secondaryText: secondaryTextColor,
                    ),

                    const SizedBox(height: 20),

                    // ── Pricing Preview Pill ────────────────────────
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: dark ? 0.15 : 0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.verified_rounded,
                            size: 16,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Obx(() {
                              final price = cfg.getPriceForPlan('6_months', 150);
                              return Text(
                                'Plans from $price ETB • 6 Months to 4 Years',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              );
                            }),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    // ── Primary Action Button ────────────────────────
                    Container(
                      width: double.infinity,
                      height: 54,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            AppColors.primary,
                            Color(0xFF009688),
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.35),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () => Get.offNamed(Routes.premium),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'View Plans & Upgrade',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 0.2,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(
                              Icons.arrow_forward_rounded,
                              size: 18,
                              color: Colors.white,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _featureCard({
    required IconData icon,
    required List<Color> iconGradient,
    required String title,
    required String subtitle,
    required Color cardBg,
    required Color borderColor,
    required Color primaryText,
    required Color secondaryText,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: iconGradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: iconGradient.first.withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Center(
              child: Icon(icon, color: Colors.white, size: 22),
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
                    color: primaryText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: secondaryText,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
