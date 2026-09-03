import 'package:flutter/material.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

/// Picks the right badge based on user status string.
class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case 'active':
        return const _GoldPremiumBadge();
      case 'pending':
        return const _PendingBadge();
      default:
        return const _FreeBadge();
    }
  }
}

// ── Gold gradient pill — premium users ───────────────────────────────────────

class _GoldPremiumBadge extends StatelessWidget {
  const _GoldPremiumBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFD700), Color(0xFFFFA000)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD700).withValues(alpha: 0.4),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, size: 11, color: Colors.white),
          SizedBox(width: 3),
          Text(
            'PREMIUM',
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Amber pill — pending payment ─────────────────────────────────────────────

class _PendingBadge extends StatelessWidget {
  const _PendingBadge();

  @override
  Widget build(BuildContext context) {
    final dark = AppHelperFunctions.isDark(context);
    final accentColor = dark ? const Color(0xFFFFB020) : const Color(0xFFD97706);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: dark ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: accentColor.withValues(alpha: dark ? 0.8 : 0.4),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.access_time_rounded, size: 11, color: accentColor),
          const SizedBox(width: 3),
          Text(
            'PENDING',
            style: TextStyle(
              color: accentColor,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Subtle outline pill — free users ─────────────────────────────────────────

class _FreeBadge extends StatelessWidget {
  const _FreeBadge();

  @override
  Widget build(BuildContext context) {
    final dark = AppHelperFunctions.isDark(context);

    final textColor = dark ? Colors.white70 : const Color(0xFF475569);
    final borderColor = dark
        ? Colors.white.withValues(alpha: 0.22)
        : const Color(0xFFCBD5E1);
    final bgColor = dark
        ? Colors.white.withValues(alpha: 0.08)
        : const Color(0xFFF1F5F9);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: borderColor,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.school_rounded,
            size: 11,
            color: textColor,
          ),
          const SizedBox(width: 3.5),
          Text(
            'FREE',
            style: TextStyle(
              color: textColor,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
