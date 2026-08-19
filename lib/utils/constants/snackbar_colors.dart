import 'package:flutter/material.dart';

/// Brand-aligned color tokens for toast and snackbar system.
class SnackbarColors {
  SnackbarColors._();

  /// Container background in light mode.
  static const Color lightSurface = Color(0xFF1E2323);

  /// Container background in dark mode.
  static const Color darkSurface = Color(0xFF2A3333);

  /// Primary text on lightSurface.
  static const Color lightText = Color(0xFFF5F7F7);

  /// Primary text on [darkSurface] — slightly softer white (contrast ≈ 12:1).
  static const Color darkText = Color(0xFFF0F2F2);

  /// Secondary / subtitle text on [lightSurface].
  static const Color lightSubtext = Color(0xFFACB5B5);

  /// Secondary / subtitle text on [darkSurface].
  static const Color darkSubtext = Color(0xFF8FA3A3);

  /// Dismiss icon color on [lightSurface] (semi-transparent white).
  static const Color lightDismiss = Color(0xB3F5F7F7); // white 70%

  /// Dismiss icon color on [darkSurface].
  static const Color darkDismiss = Color(0xB3F0F2F2); // white 70%

  /// Success variant accent color.
  static const Color success = Color(0xFF22C55E);

  /// Error — bright red.
  static const Color error = Color(0xFFEF4444);

  /// Warning — amber.
  static const Color warning = Color(0xFFF59E0B);

  /// Info — primary teal, matches the app's brand color.
  static const Color info = Color(0xFF14B8A6);

  /// Action label on light-mode surface.
  static const Color actionLight = Color(0xFF14B8A6);

  /// Action label on dark-mode surface.
  static const Color actionDark = Color(0xFF2DD4BF);

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Returns the correct surface color for the given [brightness].
  static Color surface(Brightness brightness) =>
      brightness == Brightness.light ? lightSurface : darkSurface;

  /// Returns the correct primary text color for the given [brightness].
  static Color text(Brightness brightness) =>
      brightness == Brightness.light ? lightText : darkText;

  /// Returns the correct subtext color for the given [brightness].
  static Color subtext(Brightness brightness) =>
      brightness == Brightness.light ? lightSubtext : darkSubtext;

  /// Returns the correct dismiss icon color for the given [brightness].
  static Color dismiss(Brightness brightness) =>
      brightness == Brightness.light ? lightDismiss : darkDismiss;

  /// Returns the correct action label color for the given [brightness].
  static Color action(Brightness brightness) =>
      brightness == Brightness.light ? actionLight : actionDark;
}
