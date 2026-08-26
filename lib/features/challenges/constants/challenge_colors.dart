import 'package:flutter/material.dart';

class ChallengeColors {
  ChallengeColors._();

  // Status & Semantic Colors
  static const Color live = Color(0xFFEF4444); // Live round (Red/Rose)
  static const Color scheduled = Color(0xFF2563EB); // Upcoming round (Royal Blue)
  static const Color completed = Color(0xFF10B981); // Completed/Review round (Emerald)
  static const Color accent = Color(0xFF0284C7); // Challenge Sky Blue accent
  static const Color streamNatural = Color(0xFF0284C7); // Natural Stream Chip
  static const Color streamSocial = Color(0xFF0EA5E9); // Social Stream Chip

  // Podium Rank Colors
  static const Color gold = Color(0xFFF59E0B); // 1st Place
  static const Color silver = Color(0xFF94A3B8); // 2nd Place
  static const Color bronze = Color(0xFFD97706); // 3rd Place

  // Streak & Fire Accents
  static const Color streakFire = Color(0xFFF97316); // Orange Flame
  static const Color streakBgLight = Color(0xFFFFF7ED);
  static const Color streakBgDark = Color(0xFF2A1C0E);

  // Backgrounds & Surface Tints
  static const Color liveTintLight = Color(0xFFFEF2F2);
  static const Color scheduledTintLight = Color(0xFFEFF6FF);
  static const Color completedTintLight = Color(0xFFECFDF5);
}
