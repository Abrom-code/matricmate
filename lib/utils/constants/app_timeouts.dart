/// Timeout durations for network operations throughout the app.
///
/// Every Supabase / network call should use one of these constants via
/// `.timeout(AppTimeouts.xxx)` so that the UI never hangs indefinitely.
class AppTimeouts {
  AppTimeouts._();

  // ── Startup / loading screen ───────────────────────────────────────────────

  /// Timeout for verifying user account against backend.
  static const Duration verify = Duration(seconds: 8);

  /// Timeout for fetching all subjects from remote on first launch.
  static const Duration initFromRemote = Duration(seconds: 15);

  /// Time allowed to refresh entrance/model exam counts from remote.
  static const Duration entranceCounts = Duration(seconds: 6);

  // ── General network operations ─────────────────────────────────────────────

  /// Auth round-trips (sign up, login, OTP verify, password update).
  static const Duration auth = Duration(seconds: 15);

  /// Standard DB queries (select, insert, update, upsert).
  static const Duration query = Duration(seconds: 12);

  /// Server-side RPC function calls.
  static const Duration rpc = Duration(seconds: 15);

  /// File uploads (receipt images, profile photos).
  static const Duration upload = Duration(seconds: 30);

  /// Delete operations (account, subject, notifications).
  static const Duration delete = Duration(seconds: 10);

  /// Bulk sync operations (notification sync, challenge list fetches).
  static const Duration sync = Duration(seconds: 20);

  /// Full subject / entrance download (large data transfers).
  static const Duration download = Duration(seconds: 60);

  /// Best-effort calls that silently fail (FCM token save, read receipts).
  static const Duration bestEffort = Duration(seconds: 5);
}
