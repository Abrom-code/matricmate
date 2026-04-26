import 'package:matricmate/data/database/database_service.dart';
import 'package:matricmate/features/exam/models/subject_model.dart';
import 'package:matricmate/utils/exceptions/exeption_handler.dart';
import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SyncRepository {
  final supabase = Supabase.instance.client;
  final DatabaseService _dbService = DatabaseService.instance;

  Future<void> insertBatch(String table, Map<String, dynamic> value) async {
    try {
      final db = await _dbService.database;
      final batch = db.batch();

      batch.insert(table, value, conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      throw AppExceptionHandler.handle(e);
    }
  }

  Future<void> updateBatch(SubjectMoModel s, Map<String, dynamic> local) async {
    try {
      final db = await _dbService.database;
      final batch = db.batch();

      batch.update(
        'subjects',
        {...s.toMap(), 'is_downloaded': local['is_downloaded']},
        where: 'id = ?',
        whereArgs: [s.id],
      );
    } catch (e) {
      throw AppExceptionHandler.handle(e);
    }
  }

  Future<void> deleteBatch(Map<String, dynamic> local) async {
    try {
      final db = await _dbService.database;
      final batch = db.batch();

      batch.delete('subjects', where: 'id = ?', whereArgs: [local['id']]);
    } catch (e) {
      throw AppExceptionHandler.handle(e);
    }
  }

  Future<void> commitBatch() async {
    try {
      final db = await _dbService.database;
      final batch = db.batch();

      await batch.commit(noResult: true);
    } catch (e) {
      throw AppExceptionHandler.handle(e);
    }
  }

  Future<List<Map<String, dynamic>>> getBySubjectId(
    String table,
    List<String> subjectIds,
  ) async {
    try {
      return await supabase
          .from('chapters')
          .select()
          .inFilter('subject_id', subjectIds);
    } catch (e) {
      throw AppExceptionHandler.handle(e);
    }
  }

  Future<List<Map<String, dynamic>>> getPassages(List<int> passageIds) async {
    try {
      return await supabase
          .from('passages')
          .select()
          .inFilter('id', passageIds);
    } catch (e) {
      throw AppExceptionHandler.handle(e);
    }
  }
}
