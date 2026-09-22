import 'package:flutter/foundation.dart';
import 'package:matricmate/data/services/device_service.dart';
import 'package:matricmate/utils/constants/app_timeouts.dart';
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
    String deviceId, {
    String? email,
  }) async {
    try {
      final userEmail = email?.toLowerCase().trim() ??
          _supabase.auth.currentUser?.email?.toLowerCase().trim();
      if (isWhitelistedTester(userEmail)) {
        // Reviewer/admin test account: automatically update session device without ever blocking
        try {
          final deviceInfo = await DeviceService.getDeviceInfo();
          final effectiveDeviceId =
              deviceId.isNotEmpty ? deviceId : deviceInfo.deviceId;
          await _supabase.rpc(
            'bind_user_device',
            params: {
              'p_device_id': effectiveDeviceId,
              'p_device_model': deviceInfo.deviceModel,
              'p_os_version': deviceInfo.osVersion,
            },
          ).timeout(AppTimeouts.bestEffort);
        } catch (_) {}
        return SessionValidationResult.allowed;
      }

      // Fetch persistent device metadata (brand, model, OS)
      final deviceInfo = await DeviceService.getDeviceInfo();
      final effectiveDeviceId = deviceId.isNotEmpty ? deviceId : deviceInfo.deviceId;

      // 1. Primary: Server-side secure RPC enforcement
      try {
        final rpcRes = await _supabase.rpc(
          'bind_user_device',
          params: {
            'p_device_id': effectiveDeviceId,
            'p_device_model': deviceInfo.deviceModel,
            'p_os_version': deviceInfo.osVersion,
          },
        ).timeout(AppTimeouts.query);

        if (rpcRes is Map) {
          final status = rpcRes['status']?.toString();
          if (status == 'allowed') {
            return SessionValidationResult.allowed;
          } else if (status == 'blocked') {
            return SessionValidationResult.blocked;
          }
        }
      } catch (rpcErr) {
        if (kDebugMode) {
          debugPrint('[SessionService] bind_user_device RPC failed, using fallback check: $rpcErr');
        }
      }

      // 2. Direct table fallback if RPC is not deployed
      final existing = await _supabase
          .from('user_sessions')
          .select()
          .eq('user_id', uid)
          .maybeSingle()
          .timeout(AppTimeouts.query);

      // First login or device unlocked by admin (device_id is null)
      if (existing == null || existing['device_id'] == null) {
        await _supabase.from('user_sessions').upsert({
          'user_id': uid,
          'device_id': effectiveDeviceId,
          'device_model': deviceInfo.deviceModel,
          'os_version': deviceInfo.osVersion,
          'last_active_at': DateTime.now().toIso8601String(),
        }, onConflict: 'user_id').timeout(AppTimeouts.query);
        return SessionValidationResult.allowed;
      }

      // Same device -> allow and refresh last_active_at
      if (existing['device_id'] == effectiveDeviceId) {
        try {
          await _supabase.from('user_sessions').update({
            'last_active_at': DateTime.now().toIso8601String(),
          }).eq('user_id', uid).timeout(AppTimeouts.bestEffort);
        } catch (_) {}
        return SessionValidationResult.allowed;
      }

      // Different device -> block
      return SessionValidationResult.blocked;
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('[SessionService] validateSessionDetailed error: $e\n$st');
      }
      return SessionValidationResult.error;
    }
  }

  /// Convenience wrapper — true only when explicitly allowed.
  Future<bool> validateSession(
    String uid,
    String deviceId, {
    String? email,
  }) async {
    final result = await validateSessionDetailed(uid, deviceId, email: email);
    return result == SessionValidationResult.allowed;
  }

  // ── Realtime device-change watch ───────────────────────────────────────

  /// Watches this user's session row; fires [onDeviceChanged] on device mismatch.
  void watchSession({
    required String uid,
    required String currentDeviceId,
    String? email,
    required void Function() onDeviceChanged,
  }) {
    final userEmail = email?.toLowerCase().trim() ??
        _supabase.auth.currentUser?.email?.toLowerCase().trim();
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
