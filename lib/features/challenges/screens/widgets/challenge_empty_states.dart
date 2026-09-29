import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/constants/sizes.dart';

class ChallengeEmptyState extends StatelessWidget {
  const ChallengeEmptyState({
    super.key,
    required this.title,
    required this.subtitle,
    required this.dark,
    this.icon,
  });

  final String title;
  final String subtitle;
  final bool dark;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: dark ? 0.18 : 0.08),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: dark ? 0.30 : 0.18),
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Icon(
                  icon ?? Iconsax.cup_copy,
                  size: 36,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: AppSizes.md),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                height: 1.45,
                color: dark ? AppColors.darkGrey : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChallengeOfflineState extends StatelessWidget {
  const ChallengeOfflineState({
    super.key,
    required this.dark,
    required this.isRefreshing,
    required this.onRefresh,
    this.icon = Icons.wifi_off_rounded,
    this.description,
  });

  final bool dark;
  final bool isRefreshing;
  final VoidCallback onRefresh;
  final IconData icon;
  final String? description;

  @override
  Widget build(BuildContext context) {
    final offlineIconColor =
        dark ? AppColors.darkGrey : AppColors.textSecondary;
    final refreshColor = dark ? Colors.white : Colors.black;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 1. No internet icon
            Icon(
              icon,
              size: 46,
              color: offlineIconColor,
            ),
            const SizedBox(height: 12),

            // 2. Short description
            Text(
              description ?? "You're offline. Check your connection.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: dark ? AppColors.darkGrey : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 14),

            // 3. Refresh icon / circular loading in place
            SizedBox(
              width: 40,
              height: 40,
              child: Center(
                child: isRefreshing
                    ? SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          valueColor: AlwaysStoppedAnimation<Color>(refreshColor),
                        ),
                      )
                    : IconButton(
                        onPressed: onRefresh,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 40,
                          minHeight: 40,
                        ),
                        icon: Icon(
                          Icons.refresh_rounded,
                          size: 26,
                          color: refreshColor,
                        ),
                        tooltip: 'Refresh',
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
