import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

/// A reusable collapsible explanation box used on both the question screen
/// and the review screen.
///
/// - Tap anywhere on the box to expand/collapse.
/// - Language toggle pill is only visible when expanded.
/// - [languageSelected] is an [RxString] so it reactively rebuilds.
/// - [onLanguageChange] switches the language without collapsing the box.
class AppExplanationBox extends StatelessWidget {
  const AppExplanationBox({
    super.key,
    required this.explanationEn,
    required this.explanationAm,
    required this.expanded,
    required this.onToggle,
    required this.languageSelected,
    required this.onLanguageChange,
  });

  final String explanationEn;
  final String explanationAm;
  final bool expanded;
  final VoidCallback onToggle;
  final RxString languageSelected;
  final ValueChanged<String> onLanguageChange;

  @override
  Widget build(BuildContext context) {
    final dark = AppHelperFunctions.isDark(context);

    // Tinted teal background — signals "explanation" without being loud
    final bgColor = dark
        ? AppColors.primary.withValues(alpha: 0.10)
        : AppColors.primary.withValues(alpha: 0.06);
    final borderColor = AppColors.primary.withValues(alpha: dark ? 0.30 : 0.25);

    return GestureDetector(
      onTap: onToggle,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.lightbulb_outline_rounded,
                        color: AppColors.primary,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Explanation',
                        style: Theme.of(context).textTheme.labelSmall!.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      // language toggle — absorbs its tap so it doesn't
                      // bubble up and trigger the outer toggle
                      if (expanded)
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {},
                          child: Obx(
                            () => _LangToggle(
                              selected: languageSelected.value,
                              dark: dark,
                              onTap: onLanguageChange,
                            ),
                          ),
                        ),
                      if (!expanded)
                        Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: AppColors.primary.withValues(alpha: 0.8),
                          size: 20,
                        ),
                      const SizedBox(width: 4),
                    ],
                  ),
                ],
              ),
            ),

            // ── Body ────────────────────────────────────────────────────
            if (expanded) ...[
              Divider(height: 1, color: AppColors.primary.withValues(alpha: 0.15)),
              Obx(
                () => Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    languageSelected.value == 'AM'
                        ? explanationAm
                        : explanationEn,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.7,
                      letterSpacing: 0.1,
                      color: dark
                          ? AppColors.white.withValues(alpha: 0.85)
                          : AppColors.darkerGrey,
                    ),
                  ),
                ),
              ),
            ] else
              const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}

// ── Language toggle pill ─────────────────────────────────────────────────────

class _LangToggle extends StatelessWidget {
  const _LangToggle({
    required this.selected,
    required this.dark,
    required this.onTap,
  });

  final String selected;
  final bool dark;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: dark
            ? AppColors.primary.withValues(alpha: 0.18)
            : AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [_pill('En', 'EN'), _pill('አማ', 'AM')],
      ),
    );
  }

  Widget _pill(String label, String value) {
    final isSelected = selected == value;
    return GestureDetector(
      onTap: () => onTap(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? dark
                    ? AppColors.primary.withValues(alpha: 0.35)
                    : AppColors.primary.withValues(alpha: 0.18)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isSelected
                ? AppColors.primary
                : dark
                ? AppColors.primary.withValues(alpha: 0.6)
                : AppColors.primary.withValues(alpha: 0.55),
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
