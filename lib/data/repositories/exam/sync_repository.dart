import 'package:matricmate/data/database/database_service.dart';
import 'package:matricmate/features/exam/models/subject_model.dart';
import 'package:matricmate/utils/exceptions/exeption_handler.dart';
import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SyncRepository {
  final supabase = Supabase.instance.client;
  final DatabaseService _dbService = DatabaseService.instance;

  // Shared batch variable
  Batch? _activeBatch;

  Future<Batch> _getBatch() async {
    if (_activeBatch == null) {
      final db = await _dbService.database;
      _activeBatch = db.batch();
    }
    return _activeBatch!;
  }

  Future<void> insertBatch(String table, Map<String, dynamic> value) async {
    final batch = await _getBatch();
    batch.insert(table, value, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateBatch(SubjectMoModel s, int localDownloadStatus) async {
    try {
      final batch = await _getBatch();

      final data = s.toMap();

      data['is_downloaded'] = localDownloadStatus;

      batch.update('subjects', data, where: 'id = ?', whereArgs: [s.id]);
    } catch (e) {
      throw AppExceptionHandler.handle(e);
    }
  }

  Future<void> deleteBatch(Map<String, dynamic> local) async {
    final batch = await _getBatch();
    batch.delete('subjects', where: 'id = ?', whereArgs: [local['id']]);
  }

  Future<void> commitBatch() async {
    if (_activeBatch != null) {
      await _activeBatch!.commit(noResult: true);
      _activeBatch = null;
    }
  }

  // API Methods
  Future<List<Map<String, dynamic>>> getBySubjectId(
    String table,
    List<String> ids,
  ) async {
    return await supabase.from(table).select().inFilter('subject_id', ids);
  }

  Future<List<Map<String, dynamic>>> getPassages(List<int> passageIds) async {
    return await supabase.from('passages').select().inFilter('id', passageIds);
  }
}
