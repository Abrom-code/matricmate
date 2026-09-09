import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:matricmate/features/notifications/controllers/notifications_controller.dart';
import 'package:matricmate/features/notifications/models/notification_model.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

/// Modal bottom sheet for selecting notification filters.
class NotificationFilterSheet extends StatelessWidget {
  const NotificationFilterSheet({super.key});

  /// Opens the filter bottom sheet with haptic feedback.
  static void show(BuildContext context) {
    HapticFeedback.lightImpact();
    Get.bottomSheet(
      const NotificationFilterSheet(),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  @override
  Widget build(BuildContext context) {
    final dark = AppHelperFunctions.isDark(context);
    final ctrl = NotificationsController.instance;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.75,
          ),
          decoration: BoxDecoration(
            color: dark ? AppColors.darkCard : AppColors.white,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(28),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: dark ? 0.40 : 0.10),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Drag Handle ─────────────────────────────────────────
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: dark
                        ? AppColors.darkBorder
                        : const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // ── Sheet Header ─────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(
                              alpha: dark ? 0.22 : 0.10,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.tune_rounded,
                              size: 18,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Filter Notifications',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                            color: dark
                                ? AppColors.white
                                : const Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                    Obx(() {
                      final hasFilter =
                          ctrl.selectedFilter.value != NotificationFilter.all;
                      if (!hasFilter) return const SizedBox.shrink();

                      return TextButton(
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          ctrl.setFilter(NotificationFilter.all);
                          Get.back();
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          foregroundColor: AppColors.primary,
                        ),
                        child: const Text(
                          'Reset all',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),

              const SizedBox(height: 12),
              Divider(
                height: 1,
                color: dark
                    ? AppColors.darkBorder.withValues(alpha: 0.5)
                    : const Color(0xFFF1F5F9),
              ),
              const SizedBox(height: 8),

              // ── Filter Options List ───────────────────────────────────
              Flexible(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  child: Obx(() {
                    final selected = ctrl.selectedFilter.value;
                    final filters = ctrl.availableFilters;

                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: filters.map((filter) {
                        final isSelected = filter == selected;
                        final count = ctrl.countForFilter(filter);
                        final color = filter.color;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                ctrl.setFilter(filter);
                                Get.back();
                              },
                              borderRadius: BorderRadius.circular(14),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 11,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? color.withValues(
                                          alpha: dark ? 0.16 : 0.08,
                                        )
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isSelected
                                        ? color.withValues(alpha: 0.7)
                                        : Colors.transparent,
                                    width: 1.2,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    // Category Icon Container
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: color.withValues(
                                          alpha: dark ? 0.22 : 0.12,
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        filter.icon,
                                        size: 18,
                                        color: color,
                                      ),
                                    ),
                                    const SizedBox(width: 12),

                                    // Category Label
                                    Expanded(
                                      child: Text(
                                        filter.label,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: isSelected
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                          color: isSelected
                                              ? (dark
                                                  ? AppColors.textWhite
                                                  : const Color(0xFF0F172A))
                                              : (dark
                                                  ? const Color(0xFFCBD5E1)
                                                  : const Color(0xFF334155)),
                                        ),
                                      ),
                                    ),

                                    // Count Pill
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2.5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? color
                                            : (dark
                                                ? AppColors.darkSurface
                                                : const Color(0xFFF1F5F9)),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        '$count',
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w700,
                                          color: isSelected
                                              ? Colors.white
                                              : (dark
                                                  ? AppColors.darkGrey
                                                  : AppColors.textSecondary),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),

                                    // Checkmark indicator
                                    Icon(
                                      isSelected
                                          ? Icons.check_circle_rounded
                                          : Icons.circle_outlined,
                                      size: 20,
                                      color: isSelected
                                          ? color
                                          : (dark
                                              ? AppColors.darkBorder
                                              : const Color(0xFFCBD5E1)),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  }),
                ),
              ),

              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
