import 'package:matricmate/data/database/database_service.dart';
import 'package:matricmate/data/services/session_service.dart';
import 'package:matricmate/utils/constants/app_timeouts.dart';
import 'package:matricmate/utils/exceptions/exception_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:matricmate/features/authentication/models/user_model.dart';

/// SAVE (UPSERT)
class UserRepository {
  final SupabaseClient _supabase = Supabase.instance.client;
  final DatabaseService databaseService = DatabaseService.instance;
  String? get _uid => _supabase.auth.currentUser?.id;

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
      await _supabase.from('users').upsert(user.toJson(), onConflict: 'id').timeout(AppTimeouts.query);

      await databaseService.insetData('user', user.toMap());
    } catch (e) {
      throw AppExceptionHandler.handle(e);
    }
  }

  Future<UserModel?> fetchCurrentUserDetails() async {
    final uid = _uid;
    if (uid == null) return null;

    final data = await _supabase
        .from('users')
        .select()
        .eq('id', uid)
        .maybeSingle()
        .timeout(AppTimeouts.query);

    if (data == null) return null;

    return UserModel.fromJson(data);
  }

  Future<void> updateFullUserRecord(UserModel user) async {
    try {
      await _supabase.from('users').update(user.toJson()).eq('id', user.id).timeout(AppTimeouts.query);

      await databaseService.insetData('user', user.toMap());
    } catch (e) {
      throw AppExceptionHandler.handle(e);
    }
  }

  Future<void> deleteUserRecord(String userId) async {
    try {
      // 1. Clean up payment receipt images in storage
      try {
        final receipts = await _supabase
            .from('payment_receipts')
            .select('receipt_path')
            .eq('user_id', userId)
            .timeout(AppTimeouts.delete);

        if (receipts.isNotEmpty) {
          final filesToDelete = receipts
              .map((e) => e['receipt_path']?.toString().trim() ?? '')
              .where((p) => p.isNotEmpty)
              .toList();

          if (filesToDelete.isNotEmpty) {
            try {
              await _supabase.storage.from('receipts').remove(filesToDelete).timeout(AppTimeouts.bestEffort);
            } catch (_) {}
          }
        }
      } catch (_) {}

      // 2. Remove user session
      try {
        await SessionService().removeSession(userId);
      } catch (_) {}

      // 3. Clear local user table
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
