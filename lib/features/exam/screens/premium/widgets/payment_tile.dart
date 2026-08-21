import 'package:flutter/material.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

Widget paymentTile({
  required String title,
  required String subtitle,
  required IconData icon,
  bool selected = false,
  required BuildContext context,
  VoidCallback? onTap,
  required bool isFeatured,
  Widget? detail,
  bool showIcon = true,
}) {
  final dark = AppHelperFunctions.isDark(context);

  final cardBg = selected
      ? (dark ? const Color(0xFF1E2922) : const Color(0xFFF0FDF4))
      : (dark ? const Color(0xFF18181B) : Colors.white);

  final borderColor = selected
      ? AppColors.primary
      : (dark ? const Color(0xFF27272A) : const Color(0xFFE4E4E7));

  // Distinct brand color hints based on method title
  final brandColor = _getBrandColor(title);

  return GestureDetector(
    onTap: onTap,
    child: Stack(
      clipBehavior: Clip.none,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: borderColor,
              width: selected ? 2 : 1,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: dark ? 0.2 : 0.02),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: brandColor.withValues(alpha: dark ? 0.18 : 0.10),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Icon(
                        icon,
                        color: brandColor,
                        size: 24,
                      ),
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
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            letterSpacing: -0.2,
                            color: dark ? Colors.white : const Color(0xFF09090B),
                          ),
                        ),
                        if (subtitle.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            style: TextStyle(
                              color: dark
                                  ? const Color(0xFFA1A1AA)
                                  : const Color(0xFF71717A),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (showIcon)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: selected ? AppColors.primary : Colors.transparent,
                        border: Border.all(
                          color: selected
                              ? AppColors.primary
                              : (dark
                                  ? const Color(0xFF52525B)
                                  : const Color(0xFFD4D4D8)),
                          width: 2,
                        ),
                      ),
                      child: selected
                          ? const Icon(
                              Icons.check,
                              size: 14,
                              color: Colors.white,
                            )
                          : null,
                    ),
                ],
              ),
              if (detail != null) detail,
            ],
          ),
        ),

        if (isFeatured)
          Positioned(
            top: -6,
            right: 18,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.35),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Text(
                'RECOMMENDED',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

Color _getBrandColor(String title) {
  final lower = title.toLowerCase();
  if (lower.contains('telebirr')) {
    return const Color(0xFF007AFF);
  } else if (lower.contains('cbe')) {
    return const Color(0xFF7C3AED);
  } else if (lower.contains('abyssinia') || lower.contains('boa')) {
    return const Color(0xFFD97706);
  } else if (lower.contains('mpesa') || lower.contains('m-pesa')) {
    return const Color(0xFF10B981);
  } else if (lower.contains('awash')) {
    return const Color(0xFF0284C7);
  }
  return AppColors.primary;
}
