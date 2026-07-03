import 'dart:convert';

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
    batch.insert(
      table,
      _sanitizeFor(table, value),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
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

  // ── Download entrance + model tests (used during sync) ─────────────────────

  Future<void> downloadEntranceTests(List<int> subjectIds) async {
    try {
      final db = await _dbService.database;
      final batch = db.batch();

      final tests = await supabase
          .from('tests')
          .select()
          .inFilter('subject_id', subjectIds)
          .inFilter('type', ['entrance', 'model']);

      final List<int> testIds = [];
      for (var t in tests) {
        testIds.add(t['id']);
        batch.insert(
          'tests',
          _sanitizeFor('tests', t),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      if (testIds.isEmpty) {
        await batch.commit(noResult: true);
        return;
      }

      final questionsData = await supabase
          .from('questions')
          .select()
          .inFilter('test_id', testIds);

      final Set<int> passageIds = {};
      final Set<String> imgUrls = {};

      for (var q in questionsData) {
        final question = QuestionModel.fromMap(q);
        if (question.passageId != null) passageIds.add(question.passageId!);
        if (question.imageUrl != null) imgUrls.add(question.imageUrl!);
        batch.insert(
          'questions',
          question.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      if (passageIds.isNotEmpty) {
        final passages = await supabase
            .from('passages')
            .select()
            .inFilter('id', passageIds.toList());
        for (var p in passages) {
          batch.insert(
            'passages',
            _sanitizeFor('passages', p),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }

      if (imgUrls.isNotEmpty) {
        await AppHelperFunctions.downloadImages(imgUrls);
      }

      await batch.commit(noResult: true);
    } catch (e) {
      throw AppExceptionHandler.handle(e);
    }
  }

  // ── API helpers ─────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getBySubjectId(
    String table,
    List<String> ids,
  ) async {
    return await supabase.from(table).select().inFilter('subject_id', ids);
  }

  Future<List<Map<String, dynamic>>> getPassages(List<int> passageIds) async {
    return await supabase.from('passages').select().inFilter('id', passageIds);
  }

  // ── Sanitization ────────────────────────────────────────────────────────────

  /// Columns that exist in the local SQLite schema per table.
  /// Any Supabase column NOT in this set is stripped before insert
  /// (e.g. created_at on questions, which Supabase has but SQLite doesn't).
  static const _knownColumns = <String, Set<String>>{
    'subjects': {'id', 'name', 'is_natural', 'is_common', 'is_downloaded'},
    'chapters': {'id', 'subject_id', 'grade', 'chapter_number', 'title'},
    'tests': {
      'id', 'subject_id', 'grade', 'chapter_id',
      'title', 'type', 'question_count', 'time', 'created_at',
    },
    'passages': {'id', 'content', 'title', 'image_url'},
    // questions go through QuestionModel.toMap() — not sanitized here
  };

  /// Public static accessor so SyncingController can sanitize test maps
  /// without going through the shared batch.
  static Map<String, dynamic> sanitizeTest(Map<String, dynamic> row) =>
      _sanitizeFor('tests', row);

  static Map<String, dynamic> sanitizePassage(Map<String, dynamic> row) =>
      _sanitizeFor('passages', row);

  /// Sanitizes a raw Supabase map for a specific SQLite table:
  /// 1. Strips columns not in the local schema
  /// 2. bool  → 0/1
  /// 3. DateTime → ISO string
  /// 4. List/Map (JSONB) → JSON-encoded string
  static Map<String, dynamic> _sanitizeFor(
    String table,
    Map<String, dynamic> row,
  ) {
    final allowed = _knownColumns[table];
    return Map.fromEntries(
      row.entries
          .where((e) => allowed == null || allowed.contains(e.key))
          .map((e) => MapEntry(e.key, _convert(e.value))),
    );
  }

  static dynamic _convert(dynamic value) {
    if (value is bool) return value ? 1 : 0;
    if (value is DateTime) return value.toIso8601String();
    if (value is List || value is Map) return jsonEncode(value);
    return value;
  }
}
