import 'package:matricmate/utils/helpers/snackbar_helper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Result type so callers can distinguish a network failure from a blocked device.
enum SessionValidationResult { allowed, blocked, error }

class SessionService {
  final _supabase = Supabase.instance.client;

  /// Returns [SessionValidationResult.allowed] if the device matches or a
  /// new session was created, [SessionValidationResult.blocked] if a
  /// different device is already registered, and [SessionValidationResult.error]
  /// on any network/database failure so callers don't mistakenly block the user.
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
      SnackbarHelper.error('Error', 'Session check failed. Please try again.');
      return SessionValidationResult.error;
    }
  }

  /// Convenience wrapper — returns true only when explicitly allowed.
  /// A network error returns false but callers that need to distinguish
  /// should use [validateSessionDetailed] instead.
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
      SnackbarHelper.error('Error', e.toString());
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
      SnackbarHelper.error('Error', 'Failed to update device');
    }
  }

  Future<void> removeSession(String uid) async {
    try {
      await _supabase.from('user_sessions').delete().eq('firebase_uid', uid);
    } catch (e) {
      SnackbarHelper.error('Error', 'Failed to remove session');
    }
  }
}
