import 'dart:async';
import 'dart:convert';

import 'package:matricmate/data/database/database_service.dart';
import 'package:matricmate/features/exam/models/question_model.dart';
import 'package:matricmate/features/exam/models/subject_model.dart';
import 'package:matricmate/utils/exceptions/exeption_handler.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';
import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Runs [task] while slowly ticking [onProgress] from [from] toward [to].
Future<T> _withProgress<T>(
  Future<T> task,
  double from,
  double to,
  void Function(double) onProgress,
) async {
  onProgress(from);
  double current = from;
  final ticker = Timer.periodic(const Duration(milliseconds: 120), (_) {
    current += (to - current) * 0.12;
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

      // Step 1 — chapters (0.0 → 0.15)
      final chapters = await _withProgress(
        supabase.from('chapters').select().eq('subject_id', subjectId),
        0.0, 0.15,
        (p) => onStep('Fetching chapters…', p),
      );

      // Step 2 — tests (chapter/grade only — entrance & model are downloaded
      //           separately from the entrance screen) (0.15 → 0.28)
      final tests = await _withProgress(
        supabase
            .from('tests')
            .select()
            .eq('subject_id', subjectId)
            .inFilter('type', ['chapter', 'grade']),
        0.15, 0.28,
        (p) => onStep('Fetching tests…', p),
      );

      // Step 3 — questions for chapter/grade tests only (0.28 → 0.62)
      final testIds = tests.map<int>((t) => t['id'] as int).toList();
      final questionsData = testIds.isEmpty
          ? <dynamic>[]
          : await _withProgress(
              supabase
                  .from('questions')
                  .select('*, question_sections(title)')
                  .inFilter('test_id', testIds),
              0.28, 0.62,
              (p) => onStep('Fetching questions…', p),
            );

      final Set<int> passageIds = {};
      final Set<String> imgUrls = {};
      final List<QuestionModel> questions = [];
      for (var q in questionsData) {
        final question = QuestionModel.fromMap(q);
        questions.add(question);
        if (question.passageId != null) passageIds.add(question.passageId!);
        if (question.imageUrl != null && question.imageUrl!.isNotEmpty) {
          imgUrls.add(question.imageUrl!);
        }
      }

      // Step 4 — passages (0.62 → 0.74)
      List<dynamic> passageData = [];
      if (passageIds.isNotEmpty) {
        passageData = await _withProgress(
          supabase.from('passages').select().inFilter('id', passageIds.toList()),
          0.62, 0.74,
          (p) => onStep('Fetching passages…', p),
        );
      }

      // Step 5 — write to SQLite (0.74 → 0.86)
      final batch = db.batch();
      for (var ch in chapters) {
        batch.insert('chapters', _sanitizeFor('chapters', ch),
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
      for (var t in tests) {
        batch.insert('tests', _sanitizeFor('tests', t),
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
      for (final q in questions) {
        batch.insert('questions', q.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
      for (var p in passageData) {
        batch.insert('passages', _sanitizeFor('passages', p),
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
      await _withProgress(
        batch.commit(noResult: true),
        0.74, 0.86,
        (p) => onStep('Saving to device…', p),
      );

      // Step 6 — images (0.86 → 1.0)
      if (imgUrls.isNotEmpty) {
        await _withProgress(
          AppHelperFunctions.downloadImages(imgUrls),
          0.86, 1.0,
          (p) => onStep('Downloading images…', p),
        );
      }

      onStep('Done', 1.0);
    } catch (e) {
      throw AppExceptionHandler.handle(e);
    }
  }

  /// Converts a Supabase response map to a SQLite-safe map:
  /// - bool  → 0/1  (SQLite has no boolean type)
  /// - DateTime → ISO string
  /// - List/Map (JSONB) → jsonEncoded string
  /// - Everything else passed through unchanged
  static const _knownColumns = <String, Set<String>>{
    'chapters': {'id', 'subject_id', 'grade', 'chapter_number', 'title'},
    'tests': {
      'id', 'subject_id', 'grade', 'chapter_id',
      'title', 'type', 'question_count', 'time', 'created_at',
    },
    'passages': {'id', 'content', 'title', 'image_url'},
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
  Future<List<Map<String, dynamic>>> getSupabaseSubjects({DateTime? since}) async {
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

  /// Fetches entrance/model test counts from Supabase for all subjects at once.
  /// Returns a map of subjectId → {'entrance': n, 'model': n}.
  /// Only fetches the count — no questions downloaded.
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
      final isDownloaded =
          existing.isNotEmpty ? (existing.first['is_downloaded'] as int? ?? 0) : 0;
      final isEntranceDownloaded =
          existing.isNotEmpty ? (existing.first['is_entrance_downloaded'] as int? ?? 0) : 0;

      await db.insert(
        'subjects',
        {
          'id': subject.id,
          'name': subject.name,
          'is_natural': subject.isNatural ? 1 : 0,
          'is_common': subject.isCommon ? 1 : 0,
          'is_downloaded': isDownloaded,
          'is_entrance_downloaded': isEntranceDownloaded,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
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
        {'is_downloaded': 1},
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
}
