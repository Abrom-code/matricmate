import 'package:flutter/foundation.dart';
import 'package:matricmate/utils/constants/app_timeouts.dart';
import 'package:matricmate/utils/helpers/snackbar_helper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Result type so callers can distinguish a network failure from a blocked device.
enum SessionValidationResult { allowed, blocked, error }

class SessionService {
  final _supabase = Supabase.instance.client;

  RealtimeChannel? _sessionChannel;

  /// Reviewer and test accounts that should bypass single-device restriction during app review.
  static const Set<String> _whitelistedEmails = {
    'yeabrom@gmail.com',
  };

  static bool isWhitelistedTester(String? email) {
    if (email == null || email.isEmpty) return false;
    return _whitelistedEmails.contains(email.trim().toLowerCase());
  }

  Future<SessionValidationResult> validateSessionDetailed(
    String uid,
    String deviceId,
  ) async {
    try {
      final userEmail = _supabase.auth.currentUser?.email?.toLowerCase().trim();
      if (isWhitelistedTester(userEmail)) {
        // Reviewer/test account: keep session record updated but never block
        try {
          await _supabase.from('user_sessions').upsert({
            'user_id': uid,
            'device_id': deviceId,
            'trial': 9999,
          }, onConflict: 'user_id').timeout(AppTimeouts.bestEffort);
        } catch (_) {}
        return SessionValidationResult.allowed;
      }

      final existing = await _supabase
          .from('user_sessions')
          .select()
          .eq('user_id', uid)
          .maybeSingle()
          .timeout(AppTimeouts.query);

      // First login → create session
      if (existing == null) {
        await _supabase.from('user_sessions').upsert({
          'user_id': uid,
          'device_id': deviceId,
          'trial': 3,
        }, onConflict: 'user_id').timeout(AppTimeouts.query);
        return SessionValidationResult.allowed;
      }

      // Same device → allow
      if (existing['device_id'] == deviceId) {
        return SessionValidationResult.allowed;
      }

      // Different device → block
      return SessionValidationResult.blocked;
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[SessionService] validateSessionDetailed error: $e\n$st');
      }
      return SessionValidationResult.error;
    }
  }

  /// Convenience wrapper — true only when explicitly allowed.
  Future<bool> validateSession(String uid, String deviceId) async {
    final result = await validateSessionDetailed(uid, deviceId);
    return result == SessionValidationResult.allowed;
  }

  Future<int> getTrial(String uid) async {
    try {
      final response = await _supabase
          .from('user_sessions')
          .select('trial')
          .eq('user_id', uid)
          .maybeSingle()
          .timeout(AppTimeouts.query);

      if (response == null) return -1;

      return (response['trial'] as int?) ?? 0;
    } catch (e) {
      SnackbarHelper.error(
        'Session Error',
        'Could not retrieve device change limit. Please try again.',
      );
      return -1;
    }
  }

  Future<bool> updateDevice(String uid, String deviceId, int trial) async {
    try {
      await _supabase
          .from('user_sessions')
          .update({'device_id': deviceId, 'trial': trial})
          .eq('user_id', uid)
          .timeout(AppTimeouts.query);
      return true;
    } catch (e) {
      SnackbarHelper.error(
        'Device Update Failed',
        'Could not update your device. Please try again.',
      );
      return false;
    }
  }

  Future<void> removeSession(String uid) async {
    try {
      await _supabase.from('user_sessions').delete().eq('user_id', uid).timeout(AppTimeouts.bestEffort);
    } catch (e) {
      // Non-critical — session cleanup failure should not block logout
    }
  }

  // ── Realtime device-change watch ───────────────────────────────────────

  /// Watches this user's session row; fires [onDeviceChanged] on device mismatch.
  void watchSession({
    required String uid,
    required String currentDeviceId,
    required void Function() onDeviceChanged,
  }) {
    final userEmail = _supabase.auth.currentUser?.email?.toLowerCase().trim();
    if (isWhitelistedTester(userEmail)) {
      return; // Do not terminate sessions for whitelisted review/test accounts
    }

    cancelWatch(); // always clean up before re-subscribing

    _sessionChannel = _supabase
        .channel('session_watch_$uid')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'user_sessions',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: uid,
          ),
          callback: (payload) {
            final newDeviceId = payload.newRecord['device_id'] as String?;
            if (newDeviceId != null && newDeviceId != currentDeviceId) {
              onDeviceChanged();
            }
          },
        )
        .subscribe();
  }

  /// Removes the Realtime channel. Call on logout or controller dispose.
  void cancelWatch() {
    if (_sessionChannel != null) {
      _supabase.removeChannel(_sessionChannel!);
      _sessionChannel = null;
    }
  }
}
