import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // App Basic Colors
  static const Color primary = Colors.teal;
  static const Color secondary = Colors.blueAccent;
  static const Color accent = Color(0xFFb0c7ff);
  static const Color blueAccent = Colors.blueAccent;
  static const Color amberAccent = Color(0xFFE9A94A);

  // Text Colors
  static const Color textPrimary = Color(0xFF1C1C1E);
  static const Color textSecondary = Color(0xFF6C757D);
  static const Color textWhite = Colors.white;

  // Light scaffold: warm off-white background
  static const Color light = Color(0xFFF2F3F5);
  // Dark scaffold: near-black base — deepest layer
  static const Color dark = Color(0xFF0F0F0F);
  static const Color primaryBackground = Color(0xFFF3F5FF);

  // Light surface: pure white cards
  static const Color lightContainer = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFEDF0ED);
  // Dark depth layers: each step lifts off the background
  static const Color darkCard = Color(0xFF1E1E1E); // cards on scaffold
  static const Color darkSurface = Color(
    0xFF272727,
  ); // nested containers inside cards
  static const Color darkChoice = Color.fromARGB(
    255,
    22,
    22,
    22,
  ); // choice buttons (reused in card & scaffold contexts)
  static Color darkContainer = Colors.white.withValues(alpha: 0.08);

  // Button Colors
  static const Color buttonPrimary = Colors.teal;
  static const Color buttonSecondary = Color(0xFF6C757D);
  static const Color buttonDisabled = Color(0xFFC4C4C4);

  // Border Colors
  static const Color borderPrimary = Color(0xFFDDE1E7);
  static const Color borderSecondary = Color(0xFFEDF0F2);
  static const Color darkBorder = Color(0xFF2E2E2E);

  // Input Field Colors
  static const Color darkInputFill = Color(0xFF141416);
  static const Color lightInputFill = Color(0xFFF8FAFC);
  static const Color darkInputBorder = Color(0xFF2A2D34);
  static const Color lightInputBorder = Color(0xFFE2E8F0);
  static const Color darkInputLabel = Color(0xFF94A3B8);
  static const Color lightInputLabel = Color(0xFF64748B);
  static const Color darkInputHint = Color(0xFF64748B);
  static const Color lightInputHint = Color(0xFF94A3B8);

  // Error and Validation Colors
  static const Color error = Color(0xFFd32f2f);
  static const Color success = Color(0xFF388e3c);
  static const Color warning = Color(0xFFf57c00);
  static const Color info = Color(0xFF1976d2);

  // Neutral Shades
  static const Color black = Color(0xFF0A0A0A);
  static const Color darkerGrey = Color(
    0xFF1C1C1E,
  ); // modern near-black — body text in light mode
  static const Color darkGrey = Color(0xFF939393);
  static const Color grey = Color(0xFFE0E0E0);
  static const Color softGrey = Color(0xFFF4F4F4);
  static const Color lightGrey = Color(0xFFF9F9F9);
  static const Color white = Color(0xFFFFFFFF);
}
