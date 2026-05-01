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

      //  register device
      if (existing == null) {
        await _supabase.from('user_sessions').insert({
          'firebase_uid': uid,
          'device_id': deviceId,
        });
        return true;
      }

      // Same device → allow
      if (existing['device_id'] == deviceId) {
        return true;
      }

      // Different device
      await _supabase
          .from('user_sessions')
          .update({'device_id': deviceId})
          .eq('firebase_uid', uid);

      return true;
    } catch (e) {
      SnackbarHelper.error("Error", "Session check failed.");
      return false;
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
