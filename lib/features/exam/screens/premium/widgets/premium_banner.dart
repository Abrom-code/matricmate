import 'package:flutter/material.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

class PremiumBanner extends StatelessWidget {
  final VoidCallback onTap;
  const PremiumBanner({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final dark = AppHelperFunctions.isDark(context);

    // ── Theme tokens ──────────────────────────────────────────────────
    // Dark:  near-black card, gold accent
    // Light: warm off-white card with a gold tint, same accent
    final cardBg = dark
        ? const LinearGradient(
            colors: [Color(0xFF141414), Color(0xFF1E1E1E)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : const LinearGradient(
            colors: [Color(0xFFFFFBEE), Color(0xFFFFF3CC)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );

    final titleColor = dark ? Colors.white : const Color(0xFF1C1C1E);
    final subtitleColor = dark
        ? const Color(0xFF8E8E93)
        : const Color(0xFF6C6C70);
    final iconBg = dark
        ? const Color(0xFFFFD60A).withValues(alpha: 0.15)
        : const Color(0xFFFFD60A).withValues(alpha: 0.25);
    final glowColor = const Color(0xFFFFD60A);
    final ctaBg = const Color(0xFFFFD60A);
    final ctaText = const Color(0xFF0A0A0A); // always dark on yellow

    final borderColor = dark
        ? const Color(0xFF2A2A2A)
        : const Color(0xFFFFD60A).withValues(alpha: 0.4);

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          gradient: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 1),
        ),
        child: Stack(
          children: [
            // Radial glow — top right
            Positioned(
              right: -16,
              top: -32,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      glowColor.withValues(alpha: dark ? 0.10 : 0.14),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              child: Row(
                children: [
                  // ── Icon box ────────────────────────────────────────
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: iconBg,
                    ),
                    child: const Icon(
                      Icons.bolt_rounded,
                      color: Color(0xFFFFD60A),
                      size: 22,
                    ),
                  ),

                  const SizedBox(width: 14),

                  // ── Copy ────────────────────────────────────────────
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Unlock Premium',
                          style: TextStyle(
                            color: titleColor,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.1,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Full access to all tests & content',
                          style: TextStyle(
                            color: subtitleColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 12),

                  // ── CTA ─────────────────────────────────────────────
                  GestureDetector(
                    onTap: onTap,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: ctaBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'Upgrade',
                        style: TextStyle(
                          color: ctaText,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ),
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
