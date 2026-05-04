import 'package:matricmate/utils/helpers/snackbar_helper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SessionService {
  final _supabase = Supabase.instance.client;

  Future<bool> validateSession(String uid, String deviceId) async {
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
          'trial': 0,
        });
        return true;
      }

      // Same device → allow
      if (existing['device_id'] == deviceId) {
        return true;
      }

      // Different device → block
      return false;
    } catch (e) {
      SnackbarHelper.error("Error", "Session check failed.");
      return false;
    }
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
      SnackbarHelper.error("Error", e.toString());
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
      SnackbarHelper.error("Error", "Failed to update device");
    }
  }

  Future<void> removeSession(String uid) async {
    try {
      await _supabase.from('user_sessions').delete().eq('firebase_uid', uid);
    } catch (e) {
      SnackbarHelper.error("Error", "Failed to remove session");
    }
  }
}
