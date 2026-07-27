/// Timeout durations for network operations throughout the app.
///
/// Each constant is the maximum time a single step is allowed before it is
/// silently abandoned and the app falls back to locally-cached data.
class AppTimeouts {
  AppTimeouts._();

  // ── Startup / loading screen ───────────────────────────────────────────────

  /// Time allowed to verify the user account against Supabase + Firebase
  /// (includes session validation) during the splash/loading screen.
  static const Duration verify = Duration(seconds: 8);

  /// Time allowed to fetch all subjects from remote on first launch
  /// (no local data exists yet).
  static const Duration initFromRemote = Duration(seconds: 15);

  /// Time allowed to refresh entrance/model exam counts from remote.
  static const Duration entranceCounts = Duration(seconds: 6);
}
