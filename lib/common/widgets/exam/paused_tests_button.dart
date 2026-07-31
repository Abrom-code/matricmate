import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matricmate/routes/app_routes.dart';
import 'package:matricmate/utils/constants/colors.dart';

/// Small pill button that replaces the old full-width resume banner.
/// Shows how many tests are paused; tapping opens the full list.
class PausedTestsButton extends StatelessWidget {
  const PausedTestsButton({super.key, required this.count});
  final int count;

  static const _accent = AppColors.secondary;

  @override
  Widget build(BuildContext context) {
    if (count == 0) return const SizedBox.shrink();

    return Material(
      color: _accent.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(30),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Get.toNamed(Routes.pausedTests),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.pause_circle_filled_rounded,
                color: _accent,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                count == 1 ? '1 test in progress' : '$count tests in progress',
                style: const TextStyle(
                  color: _accent,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right_rounded, color: _accent, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
