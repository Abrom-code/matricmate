import 'dart:async';
import 'dart:convert';

import 'package:matricmate/data/database/database_service.dart';
import 'package:matricmate/features/exam/models/question_model.dart';
import 'package:matricmate/features/exam/models/subject_model.dart';
import 'package:matricmate/utils/exceptions/exception_handler.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';
import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Runs [task] while smoothly ticking [onProgress] from [from] toward [to].
Future<T> _withProgress<T>(
  Future<T> task,
  double from,
  double to,
  void Function(double) onProgress,
) async {
  onProgress(from);
  double current = from;
  final ticker = Timer.periodic(const Duration(milliseconds: 60), (_) {
    current += (to - current) * 0.15;
    onProgress(current.clamp(from, to - 0.01));
  });
  try {
    return await task;
  } finally {
    ticker.cancel();
    onProgress(to);
  }
}

class SubjectRepository {
  final supabase = Supabase.instance.client;
  final DatabaseService _dbService = DatabaseService.instance;
  Future<void> downloadSubject(
    int subjectId, {
    required void Function(String step, double progress) onStep,
  }) async {
    try {
      final db = await _dbService.database;

      // Step 1 — Fetch chapters and tests in parallel (0.05 → 0.20)
      onStep('Fetching chapters and tests…', 0.05);
      final metaResults = await _withProgress(
        Future.wait([
          supabase.from('chapters').select().eq('subject_id', subjectId),
          supabase.from('tests').select().eq('subject_id', subjectId),
        ]),
        0.05,
        0.20,
        (p) => onStep('Fetching subject data…', p),
      );

      final chapters = metaResults[0] as List;
      final tests = metaResults[1] as List;
      final testIds = tests.map<int>((t) => t['id'] as int).toList();

      // Step 2 — Fetch questions for ALL tests in parallel chunks (0.20 → 0.65)
      final List<dynamic> questionsData = [];
      if (testIds.isNotEmpty) {
        final List<List<int>> chunks = [];
        const chunkSize = 20;
        for (var i = 0; i < testIds.length; i += chunkSize) {
          chunks.add(
            testIds.sublist(
              i,
              i + chunkSize > testIds.length ? testIds.length : i + chunkSize,
            ),
          );
        }

        final chunkResults = await _withProgress(
          Future.wait(
            chunks.map(
              (chunk) => supabase
                  .from('questions')
                  .select('*, question_sections(title)')
                  .inFilter('test_id', chunk),
            ),
          ),
          0.20,
          0.65,
          (p) => onStep('Fetching questions…', p),
        );

        for (final list in chunkResults) {
          questionsData.addAll(list as List);
        }
      }

      final Set<int> passageIds = {};
      final Set<String> imgUrls = {};
      final List<QuestionModel> questions = [];
      for (var q in questionsData) {
        final map = Map<String, dynamic>.from(q as Map);
        if (map['subject_id'] == null || map['subject_id'] == 0) {
          map['subject_id'] = subjectId;
        }
        final question = QuestionModel.fromMap(map);
        questions.add(question);
        if (question.passageId != null) passageIds.add(question.passageId!);
        if (question.imageUrl != null && question.imageUrl!.isNotEmpty) {
          imgUrls.add(question.imageUrl!);
        }
        if (question.explanationImageUrl != null &&
            question.explanationImageUrl!.isNotEmpty) {
          imgUrls.add(question.explanationImageUrl!);
        }
      }

      // Step 2 — Fetch passages if needed (0.60 → 0.72)
      List<dynamic> passageData = [];
      if (passageIds.isNotEmpty) {
        passageData = await _withProgress(
          supabase
              .from('passages')
              .select()
              .inFilter('id', passageIds.toList()),
          0.60,
          0.72,
          (p) => onStep('Fetching passages…', p),
        );
      }

      // Step 3 — Write to SQLite in a single transaction (0.72 → 0.86)
      final batch = db.batch();
      for (var ch in chapters) {
        batch.insert(
          'chapters',
          _sanitizeFor('chapters', ch),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      for (var t in tests) {
        batch.insert(
          'tests',
          _sanitizeFor('tests', t),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      for (final q in questions) {
        batch.insert(
          'questions',
          q.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      for (var p in passageData) {
        batch.insert(
          'passages',
          _sanitizeFor('passages', p),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await _withProgress(
        batch.commit(noResult: true),
        0.72,
        0.86,
        (p) => onStep('Saving to device…', p),
      );

      // Step 4 — Images (0.86 → 1.0)
      if (imgUrls.isNotEmpty) {
        await _withProgress(
          AppHelperFunctions.downloadImages(imgUrls),
          0.86,
          1.0,
          (p) => onStep('Downloading images…', p),
        );
      }

      onStep('Done', 1.0);
    } catch (e) {
      throw AppExceptionHandler.handle(e);
    }
  }

  /// Converts a Supabase response map to a SQLite-safe map.
  static const _knownColumns = <String, Set<String>>{
    'chapters': {'id', 'subject_id', 'grade', 'chapter_number', 'title'},
    'tests': {
      'id',
      'subject_id',
      'grade',
      'chapter_id',
      'title',
      'type',
      'question_count',
      'time',
      'created_at',
    },
    'passages': {'id', 'content', 'title', 'image_url'},
    'questions': {
      'id',
      'subject_id',
      'grade',
      'chapter_id',
      'test_id',
      'passage_id',
      'question_text',
      'image_url',
      'options',
      'correct_option_index',
      'explanation_en',
      'explanation_am',
      'explanation_image_url',
      'question_order',
      'section_id',
      'section_title',
    },
  };

  static dynamic _convert(dynamic value) {
    if (value is bool) return value ? 1 : 0;
    if (value is DateTime) return value.toIso8601String();
    if (value is List || value is Map) return jsonEncode(value);
    return value;
  }

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

  //get supabase subject
  Future<List<Map<String, dynamic>>> getSupabaseSubjects({
    DateTime? since,
  }) async {
    try {
      var q = supabase.from('subjects').select();
      if (since != null) {
        q = q.gt('updated_at', since.toUtc().toIso8601String());
      }
      return await q;
    } catch (e) {
      throw AppExceptionHandler.handle(e);
    }
  }

  Future<int> testNumbers(int id, String type) async {
    try {
      return await _dbService.getETestNumbers(id, type);
    } catch (e) {
      throw AppExceptionHandler.handle(e);
    }
  }

  /// Fetches entrance/model test counts from Supabase for all subjects.
  Future<Map<int, Map<String, int>>> remoteEntranceTestCounts(
    List<int> subjectIds,
  ) async {
    try {
      final rows = await supabase
          .from('tests')
          .select('subject_id, type')
          .inFilter('subject_id', subjectIds)
          .inFilter('type', ['entrance', 'model']);

      final Map<int, Map<String, int>> result = {};
      for (final row in rows) {
        final sid = row['subject_id'] as int;
        final type = row['type'] as String;
        result.putIfAbsent(sid, () => {'entrance': 0, 'model': 0});
        result[sid]![type] = (result[sid]![type] ?? 0) + 1;
      }
      return result;
    } catch (e) {
      throw AppExceptionHandler.handle(e);
    }
  }

  Future<void> addSubject(SubjectModel subject) async {
    try {
      final db = await _dbService.database;

      // Read both local download flags so we don't clobber them on update.
      final existing = await db.query(
        'subjects',
        columns: ['is_downloaded', 'is_entrance_downloaded'],
        where: 'id = ?',
        whereArgs: [subject.id],
        limit: 1,
      );
      final isDownloaded = existing.isNotEmpty
          ? (existing.first['is_downloaded'] as int? ?? 0)
          : 0;
      final isEntranceDownloaded = existing.isNotEmpty
          ? (existing.first['is_entrance_downloaded'] as int? ?? 0)
          : 0;

      await db.insert('subjects', {
        'id': subject.id,
        'name': subject.name,
        'is_natural': subject.isNatural ? 1 : 0,
        'is_common': subject.isCommon ? 1 : 0,
        'is_downloaded': isDownloaded,
        'is_entrance_downloaded': isEntranceDownloaded,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    } catch (e) {
      throw AppExceptionHandler.handle(e);
    }
  }

  // update entrance downloaded flag
  Future<void> updateIsEntranceDownloaded(int subjectId) async {
    try {
      final db = await _dbService.database;
      await db.update(
        'subjects',
        {'is_entrance_downloaded': 1},
        where: 'id = ?',
        whereArgs: [subjectId],
      );
    } catch (e) {
      throw AppExceptionHandler.handle(e);
    }
  }

  Future<void> updateIsDownloaded(String subject) async {
    try {
      final db = await _dbService.database;

      await db.update(
        'subjects',
        {'is_downloaded': 1, 'is_entrance_downloaded': 1},
        where: 'name = ?',
        whereArgs: [subject],
      );
    } catch (e) {
      throw AppExceptionHandler.handle(e);
    }
  }

  // local
  Future<List<Map<String, dynamic>>> getLocalSubjects() async {
    try {
      return await _dbService.getSubjects();
    } catch (e) {
      throw AppExceptionHandler.handle(e);
    }
  }

  /// Delete all downloaded content (chapters, tests, questions, passages, images) for a subject
  Future<void> deleteSubject(int subjectId) async {
    try {
      final db = await _dbService.database;

      // 1. Collect image URLs to evict from disk cache
      final questionImageRows = await db.rawQuery(
        'SELECT image_url, explanation_image_url FROM questions WHERE subject_id = ?',
        [subjectId],
      );
      final Set<String> imageUrls = {};
      for (final row in questionImageRows) {
        final img = row['image_url'] as String?;
        if (img != null && img.isNotEmpty) imageUrls.add(img);
        final expImg = row['explanation_image_url'] as String?;
        if (expImg != null && expImg.isNotEmpty) imageUrls.add(expImg);
      }

      // 2. Perform transactional deletion of questions, tests, chapters, results, and reset flags
      await db.transaction((txn) async {
        final testRows = await txn.query(
          'tests',
          columns: ['id'],
          where: 'subject_id = ?',
          whereArgs: [subjectId],
        );
        final testIds = testRows.map((r) => r['id'] as int).toList();

        if (testIds.isNotEmpty) {
          final placeholders = testIds.map((_) => '?').join(',');
          await txn.delete(
            'results',
            where: 'test_id IN ($placeholders)',
            whereArgs: testIds,
          );
        }

        await txn.delete(
          'questions',
          where: 'subject_id = ?',
          whereArgs: [subjectId],
        );
        await txn.delete(
          'tests',
          where: 'subject_id = ?',
          whereArgs: [subjectId],
        );
        await txn.delete(
          'chapters',
          where: 'subject_id = ?',
          whereArgs: [subjectId],
        );

        await txn.update(
          'subjects',
          {'is_downloaded': 0, 'is_entrance_downloaded': 0},
          where: 'id = ?',
          whereArgs: [subjectId],
        );
      });

      // 3. Evict images from cache
      if (imageUrls.isNotEmpty) {
        await AppHelperFunctions.removeCachedImages(imageUrls);
      }
    } catch (e) {
      throw AppExceptionHandler.handle(e);
    }
  }
}
