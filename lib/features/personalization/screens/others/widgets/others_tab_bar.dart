import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

enum OthersColumn { progress, pilotExam, studyPlan }

class OthersTabBar extends StatelessWidget {
  const OthersTabBar({
    super.key,
    required this.selectedColumn,
    required this.onSelect,
  });

  final OthersColumn selectedColumn;
  final ValueChanged<OthersColumn> onSelect;

  @override
  Widget build(BuildContext context) {
    final dark = AppHelperFunctions.isDark(context);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: dark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: dark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? 0.25 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          _TabPill(
            title: 'Progress',
            icon: Iconsax.chart_2_copy,
            badge: null,
            isSelected: selectedColumn == OthersColumn.progress,
            onTap: () {
              HapticFeedback.selectionClick();
              onSelect(OthersColumn.progress);
            },
            dark: dark,
          ),
          _TabPill(
            title: 'Pilot Exam',
            icon: Iconsax.timer_1_copy,
            badge: 'Soon',
            isSelected: selectedColumn == OthersColumn.pilotExam,
            onTap: () {
              HapticFeedback.selectionClick();
              onSelect(OthersColumn.pilotExam);
            },
            dark: dark,
          ),
          _TabPill(
            title: 'Study Plan',
            icon: Iconsax.calendar_tick_copy,
            badge: 'Soon',
            isSelected: selectedColumn == OthersColumn.studyPlan,
            onTap: () {
              HapticFeedback.selectionClick();
              onSelect(OthersColumn.studyPlan);
            },
            dark: dark,
          ),
        ],
      ),
    );
  }
}

class _TabPill extends StatelessWidget {
  const _TabPill({
    required this.title,
    required this.icon,
    this.badge,
    required this.isSelected,
    required this.onTap,
    required this.dark,
  });

  final String title;
  final IconData icon;
  final String? badge;
  final bool isSelected;
  final VoidCallback onTap;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 15,
                color: isSelected
                    ? Colors.white
                    : (dark ? AppColors.darkGrey : AppColors.textSecondary),
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: isSelected
                        ? Colors.white
                        : (dark ? AppColors.darkGrey : AppColors.textSecondary),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (badge != null) ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white.withValues(alpha: 0.25)
                        : (dark
                            ? const Color(0xFFF59E0B).withValues(alpha: 0.22)
                            : const Color(0xFFFEF3C7)),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    badge!,
                    style: TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w800,
                      color: isSelected
                          ? Colors.white
                          : (dark ? const Color(0xFFFBBF24) : const Color(0xFFB45309)),
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
