import 'package:firebase_auth/firebase_auth.dart';
import 'package:matricmate/data/database/database_service.dart';
import 'package:matricmate/data/services/ensure_supabase_auth.dart';
import 'package:matricmate/data/services/session_service.dart';
import 'package:matricmate/utils/exceptions/exeption_handler.dart';
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

    final result = await db.query('user', limit: 1);

    if (result.isEmpty) return null;

    return UserModel.fromMap(result.first);
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
      await _supabase.from('users').delete().eq('id', userId);
      await SessionService().removeSession(userId);

      // clear local user table so no stale data remains
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
