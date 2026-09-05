import 'package:firebase_auth/firebase_auth.dart';
import 'package:matricmate/data/database/database_service.dart';
import 'package:matricmate/data/services/ensure_supabase_auth.dart';
import 'package:matricmate/data/services/session_service.dart';
import 'package:matricmate/utils/exceptions/exception_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:matricmate/features/authentication/models/user_model.dart';

/// SAVE (UPSERT)
class UserRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final SupabaseClient _supabase = Supabase.instance.client;
  final DatabaseService databaseService = DatabaseService.instance;
  String? get _uid => _auth.currentUser?.uid;

  Future<UserModel?> getLocalUser() async {
    final db = await databaseService.database;
    final uid = _uid;

    final result = uid != null
        ? await db.query('user', where: 'id = ?', whereArgs: [uid], limit: 1)
        : await db.query('user', limit: 1);

    if (result.isEmpty) return null;

    return UserModel.fromMap(result.first);
  }

  Future<void> clearLocalUser() async {
    try {
      final db = await databaseService.database;
      await db.delete('user');
    } catch (_) {}
  }

  Future<void> saveUserRecord(UserModel user) async {
    try {
      await ensureSupabaseAuth();
      await _supabase.from('users').upsert(user.toJson(), onConflict: 'id');

      await databaseService.insetData('user', user.toMap());
    } catch (e) {
      throw AppExceptionHandler.handle(e);
    }
  }

  Future<UserModel?> fetchCurrentUserDetails() async {
    await ensureSupabaseAuth();
    final uid = _uid;
    if (uid == null) return null;

    final data = await _supabase
        .from('users')
        .select()
        .eq('id', uid)
        .maybeSingle();

    if (data == null) return null;

    return UserModel.fromJson(data);
  }

  Future<void> updateFullUserRecord(UserModel user) async {
    try {
      await ensureSupabaseAuth();
      await _supabase.from('users').update(user.toJson()).eq('id', user.id);

      await databaseService.insetData('user', user.toMap());
    } catch (e) {
      throw AppExceptionHandler.handle(e);
    }
  }

  Future<void> deleteUserRecord(String userId) async {
    try {
      await ensureSupabaseAuth();

      // 1. Clean up payment receipts and uploaded receipt images in storage
      try {
        final receipts = await _supabase
            .from('payment_receipts')
            .select('receipt_path')
            .eq('user_id', userId);

        if (receipts.isNotEmpty) {
          final filesToDelete = receipts
              .map((e) => e['receipt_path']?.toString().trim() ?? '')
              .where((p) => p.isNotEmpty)
              .toList();

          if (filesToDelete.isNotEmpty) {
            try {
              await _supabase.storage.from('receipts').remove(filesToDelete);
            } catch (_) {}
          }
        }
        await _supabase.from('payment_receipts').delete().eq('user_id', userId);
      } catch (_) {}

      // 2. Remove user session lock
      try {
        await SessionService().removeSession(userId);
      } catch (_) {}

      // 3. Remove notification reads & personal notifications
      try {
        await _supabase
            .from('notification_reads')
            .delete()
            .eq('user_id', userId);
      } catch (_) {}

      try {
        await _supabase
            .from('notifications')
            .delete()
            .eq('user_id', userId);
      } catch (_) {}

      // 4. Delete user record in Supabase
      await _supabase.from('users').delete().eq('id', userId);

      // 5. Clear local user table so no stale data remains
      final db = await databaseService.database;
      await db.delete('user');
    } catch (e) {
      throw AppExceptionHandler.handle(e);
    }
  }

  Future<void> updateLocalUser(UserModel user) async {
    try {
      await databaseService.insetData('user', user.toMap());
    } catch (e) {
      throw AppExceptionHandler.handle(e);
    }
  }
}
