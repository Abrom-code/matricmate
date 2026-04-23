import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:matricmate/utils/helpers/toast_helper.dart';

class SessionService {
  final _supabase = Supabase.instance.client;

  Future<bool> validateSession(String uid, String deviceId) async {
    try {
      final existing = await _supabase
          .from('user_sessions')
          .select()
          .eq('firebase_uid', uid)
          .eq('is_active', true)
          .maybeSingle();

      //  No session → allow
      if (existing == null) {
        await _supabase.from('user_sessions').insert({
          'firebase_uid': uid,
          'device_id': deviceId,
        });
        return true;
      }

      //  Same device → allow
      if (existing['device_id'] == deviceId) {
        return true;
      }

      //  Different device → BLOCK
      ToastHelper.error(
        "Login Blocked",
        "This account is already in use on another device.",
      );

      return false;

      //  OR replace session (better UX)
      /*
      await _supabase
          .from('user_sessions')
          .update({'is_active': false})
          .eq('firebase_uid', uid);

      await _supabase.from('user_sessions').insert({
        'firebase_uid': uid,
        'device_id': deviceId,
      });

      return true;
      */
    } catch (e) {
      ToastHelper.error("Error", "Session check failed.");
      return false;
    }
  }
}
