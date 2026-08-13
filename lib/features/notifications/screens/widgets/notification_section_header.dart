import 'package:flutter/material.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

/// Sticky-style date group header for the notifications list.
///
/// Displays labels like "Today", "Yesterday", "This Week", "Earlier"
/// to visually separate notification groups by date.
class NotificationSectionHeader extends StatelessWidget {
  const NotificationSectionHeader({super.key, required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final dark = AppHelperFunctions.isDark(context);

    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 6),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
              color: dark ? AppColors.darkGrey : AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              height: 1,
              color: (dark ? AppColors.darkGrey : AppColors.grey)
                  .withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }

  /// Groups a list of notifications by date bucket and returns the label
  /// for a given [DateTime].
  static String labelFor(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(dt.year, dt.month, dt.day);

    final diff = today.difference(date).inDays;

    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 7) return 'This Week';
    return 'Earlier';
  }
}
