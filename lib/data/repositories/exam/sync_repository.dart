import 'package:matricmate/data/database/database_service.dart';
import 'package:matricmate/features/exam/models/question_model.dart';
import 'package:matricmate/features/exam/models/subject_model.dart';
import 'package:matricmate/utils/exceptions/exeption_handler.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';
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

  Future<void> updateBatch(SubjectModel s, int localDownloadStatus) async {
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

  // download entrance tests
  Future<void> downloadEntranceTests(List<int> subjectIds) async {
    try {
      final db = await _dbService.database;
      final batch = db.batch();

      //  Fetch entrance tests for all given subjects
      final tests = await supabase
          .from('tests')
          .select()
          .inFilter('subject_id', subjectIds)
          .inFilter('type', ['entrance', 'model']);

      final List<int> testIds = [];

      for (var t in tests) {
        testIds.add(t['id']);
        batch.insert('tests', t, conflictAlgorithm: ConflictAlgorithm.replace);
      }

      //  Stop early if no tests
      if (testIds.isEmpty) {
        await batch.commit(noResult: true);
        return;
      }

      //  Fetch ONLY questions linked to those tests
      final questionsData = await supabase
          .from('questions')
          .select()
          .inFilter('test_id', testIds);

      final Set<int> passageIds = {};
      final Set<String> imgUrls = {};

      for (var q in questionsData) {
        final question = QuestionModel.fromMap(q);

        if (question.passageId != null) {
          passageIds.add(question.passageId!);
        }
        if (question.imageUrl != null) {
          imgUrls.add(question.imageUrl!);
        }

        batch.insert(
          'questions',
          question.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      //  Fetch passages used by those questions
      if (passageIds.isNotEmpty) {
        final passages = await supabase
            .from('passages')
            .select()
            .inFilter('id', passageIds.toList());

        for (var p in passages) {
          batch.insert(
            'passages',
            p,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }
      // cache images
      if (imgUrls.isNotEmpty) {
        await AppHelperFunctions.downloadImages(imgUrls);
      }

      // Commit everything
      await batch.commit(noResult: true);
    } catch (e) {
      throw AppExceptionHandler.handle(e);
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
