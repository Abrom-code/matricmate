import 'package:matricmate/utils/helpers/snackbar_helper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Result type so callers can distinguish a network failure from a blocked device.
enum SessionValidationResult { allowed, blocked, error }

class SessionService {
  final _supabase = Supabase.instance.client;

  Future<SessionValidationResult> validateSessionDetailed(
    String uid,
    String deviceId,
  ) async {
    try {
      final existing = await _supabase
          .from('user_sessions')
          .select()
          .eq('firebase_uid', uid)
          .maybeSingle();

      // First login → create session
      if (existing == null) {
        await _supabase.from('user_sessions').insert({
          'firebase_uid': uid,
          'device_id': deviceId,
          'trial': 2,
        });
        return SessionValidationResult.allowed;
      }

      // Same device → allow
      if (existing['device_id'] == deviceId) {
        return SessionValidationResult.allowed;
      }

      // Different device → block
      return SessionValidationResult.blocked;
    } catch (e) {
      if (_isNetworkError(e)) {
        SnackbarHelper.warning(
          'No Internet',
          'Could not verify your session. Check your connection.',
        );
      } else {
        SnackbarHelper.error(
          'Session Error',
          'Could not verify your session. Please try again.',
        );
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
          .eq('firebase_uid', uid)
          .maybeSingle();

      if (response == null) return 0;

      return (response['trial'] as int?) ?? 0;
    } catch (e) {
      SnackbarHelper.error(
        'Session Error',
        'Could not retrieve device change limit. Please try again.',
      );
      return 0;
    }
  }

  Future<void> updateDevice(String uid, String deviceId, int trial) async {
    try {
      await _supabase
          .from('user_sessions')
          .update({'device_id': deviceId, 'trial': trial})
          .eq('firebase_uid', uid);
    } catch (e) {
      SnackbarHelper.error(
        'Device Update Failed',
        'Could not update your device. Please try again.',
      );
    }
  }

  Future<void> removeSession(String uid) async {
    try {
      await _supabase.from('user_sessions').delete().eq('firebase_uid', uid);
    } catch (e) {
      // Non-critical — session cleanup failure should not block logout
    }
  }

  static bool _isNetworkError(Object e) {
    final s = e.toString().toLowerCase();
    return s.contains('socketexception') ||
        s.contains('failed host lookup') ||
        s.contains('network is unreachable') ||
        s.contains('connection refused') ||
        s.contains('connection reset') ||
        s.contains('connection timed out') ||
        s.contains('clientexception') ||
        s.contains('no address associated');
  }
}
