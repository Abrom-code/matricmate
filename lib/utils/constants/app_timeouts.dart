/// Timeout durations for network operations throughout the app.
class AppTimeouts {
  AppTimeouts._();

  // ── Startup / loading screen ───────────────────────────────────────────────

  /// Timeout for verifying user account against backend.
  static const Duration verify = Duration(seconds: 8);

  /// Timeout for fetching all subjects from remote on first launch.
  static const Duration initFromRemote = Duration(seconds: 15);

  /// Time allowed to refresh entrance/model exam counts from remote.
  static const Duration entranceCounts = Duration(seconds: 6);
}
