import 'package:firebase_auth/firebase_auth.dart';
import 'package:matricmate/data/database/database_service.dart';
import 'package:matricmate/utils/exceptions/exeption_handler.dart';
import 'package:sqflite/sql.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:matricmate/features/authentication/models/user_model.dart';

/// SAVE (UPSERT)
class UserRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final SupabaseClient _supabase = Supabase.instance.client;
  final DatabaseService databaseService = DatabaseService.instance;
  String? get _uid => _auth.currentUser?.uid;

  Future<void> saveUserRecord(UserModel user) async {
    try {
      await _supabase.from('users').upsert(user.toJson(), onConflict: 'id');

      final db = await databaseService.database;
      await db.insert(
        'user',
        user.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
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
        .maybeSingle();

    if (data == null) return null;

    return UserModel.fromJson(data);
  }

  Future<void> updateSingleField(
    String userId,
    Map<String, dynamic> json,
  ) async {
    try {
      json.remove('id');
      await _supabase.from('users').update(json).eq('id', userId);
    } catch (e) {
      throw AppExceptionHandler.handle(e);
    }
  }

  Future<void> updateFullUserRecord(UserModel user) async {
    try {
      await _supabase.from('users').update(user.toJson()).eq('id', user.id);

      final db = await databaseService.database;

      await db.insert(
        'user',
        user.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      throw AppExceptionHandler.handle(e);
    }
  }

  Future<void> deleteUserRecord(String userId) async {
    try {
      await _supabase.from('users').delete().eq('id', userId);
      await _supabase.from('user_sessions').delete().eq('firebase_uid', userId);
    } catch (e) {
      throw AppExceptionHandler.handle(e);
    }
  }

  Future<void> addUser(UserModel user) async {
    try {
      await databaseService.insetData('subjects', user.toMap());
    } catch (e) {
      throw AppExceptionHandler.handle(e);
    }
  }
}
