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
/// When the task completes, [onProgress] is set to [to] exactly.
Future<T> _withProgress<T>(
  Future<T> task,
  double from,
  double to,
  void Function(double) onProgress,
) async {
  onProgress(from);
  double current = from;
  // Tick every 120ms — moves ~70% of remaining gap each tick (ease-out feel)
  final ticker = Timer.periodic(const Duration(milliseconds: 120), (_) {
    current += (to - current) * 0.12;
    onProgress(current.clamp(from, to - 0.01)); // never reach `to` early
  });
  try {
    return await task;
  } finally {
    ticker.cancel();
    onProgress(to);
  }
}

class SyncRepository {
  final supabase = Supabase.instance.client;
  final DatabaseService _dbService = DatabaseService.instance;

  // ── Shared subject batch (used only during subject sync) ─────────────────

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
    batch.insert(table, _sanitizeFor(table, value),
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updateBatch(SubjectModel s, int localDownloadStatus, {int localEntranceDownloaded = 0}) async {
    try {
      final batch = await _getBatch();
      final data = s.toMap();
      data['is_downloaded'] = localDownloadStatus;
      data['is_entrance_downloaded'] = localEntranceDownloaded;
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

  // ── Per-subject entrance download with progress ───────────────────────────
  //
  // [onStep] reports named steps so the UI can show a step-based progress bar.
  // Steps: 'tests' → 'questions' → 'passages' → 'images' → 'done'

  Future<void> downloadEntranceForSubject(
    int subjectId, {
    required void Function(String step, double progress) onStep,
  }) async {
    try {
      final db = await _dbService.database;

      // Step 1 — fetch tests (0.0 → 0.15)
      final tests = await _withProgress(
        supabase.from('tests').select()
            .eq('subject_id', subjectId)
            .inFilter('type', ['entrance', 'model']),
        0.0, 0.15,
        (p) => onStep('Fetching tests…', p),
      );

      if (tests.isEmpty) { onStep('Done', 1.0); return; }

      final testIds = tests.map<int>((t) => t['id'] as int).toList();

      // Step 2 — fetch questions (0.15 → 0.50)
      final questionsData = await _withProgress(
        supabase.from('questions')
            .select('*, question_sections(title)')
            .inFilter('test_id', testIds),
        0.15, 0.50,
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

      // Step 3 — fetch passages (0.50 → 0.65)
      List<dynamic> passageData = [];
      if (passageIds.isNotEmpty) {
        passageData = await _withProgress(
          supabase.from('passages').select()
              .inFilter('id', passageIds.toList()),
          0.50, 0.65,
          (p) => onStep('Fetching passages…', p),
        );
      }

      // Step 4 — write to SQLite (0.65 → 0.80)
      onStep('Saving to device…', 0.65);
      final batch = db.batch();
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
        0.65, 0.80,
        (p) => onStep('Saving to device…', p),
      );

      // Step 5 — download images (0.80 → 1.0)
      if (imgUrls.isNotEmpty) {
        await _withProgress(
          AppHelperFunctions.downloadImages(imgUrls),
          0.80, 1.0,
          (p) => onStep('Downloading images…', p),
        );
      }

      onStep('Done', 1.0);
    } catch (e) {
      throw AppExceptionHandler.handle(e);
    }
  }
  //
  // [since] = null  → full sync (first run)
  // [since] = DateTime → only rows with updated_at > since

  Future<void> downloadEntranceTests(
    List<int> subjectIds, {
    DateTime? since,
  }) async {
    try {
      final db = await _dbService.database;
      final sinceIso = since?.toUtc().toIso8601String();

      // 1. Fetch changed/new tests
      var testsQuery = supabase
          .from('tests')
          .select()
          .inFilter('subject_id', subjectIds)
          .inFilter('type', ['entrance', 'model']);

      if (sinceIso != null) {
        testsQuery = testsQuery.gt('updated_at', sinceIso);
      }

      final tests = await testsQuery;

      // 2. Fetch changed/new questions — either scoped to new test IDs (full
      //    sync) or by updated_at (delta). This catches edits to existing
      //    questions even when their test row didn't change.
      List<dynamic> questionsData;

      if (sinceIso == null) {
        // Full sync: fetch all questions for all these tests
        final testIds = tests.map<int>((t) => t['id'] as int).toList();
        if (testIds.isEmpty) return;
        questionsData = await supabase
            .from('questions')
            .select('*, question_sections(title)')
            .inFilter('test_id', testIds);
      } else {
        // Delta: fetch questions updated since last sync.
        // We scope by subject_id and rely on updated_at to catch edits.
        // No test_id filter needed — updated_at covers all changed rows.
        if (tests.isEmpty) {
          // No new tests — just check for edited questions across these subjects
          questionsData = await supabase
              .from('questions')
              .select('*, question_sections(title)')
              .inFilter('subject_id', subjectIds)
              .gt('updated_at', sinceIso);
        } else {
          // New tests arrived — fetch questions for those new tests
          // PLUS any edited questions across all entrance subjects
          final newTestIds = tests.map<int>((t) => t['id'] as int).toList();
          final results = await Future.wait([
            supabase
                .from('questions')
                .select('*, question_sections(title)')
                .inFilter('test_id', newTestIds),
            supabase
                .from('questions')
                .select('*, question_sections(title)')
                .inFilter('subject_id', subjectIds)
                .gt('updated_at', sinceIso),
          ]);
          // Merge and deduplicate by question id
          final Map<int, dynamic> merged = {};
          for (final q in [...results[0], ...results[1]]) {
            merged[q['id'] as int] = q;
          }
          questionsData = merged.values.toList();
        }

        if (tests.isEmpty && questionsData.isEmpty) return;
      }

      // 3. Parse questions, collect passage IDs + image URLs
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

      // 4. Fetch changed passages in parallel with building the write batch
      final passageFuture = passageIds.isNotEmpty
          ? _fetchChangedPassages(passageIds.toList(), since: since)
          : Future.value(<dynamic>[]);

      final batch = db.batch();
      for (var t in tests) {
        batch.insert('tests', _sanitizeFor('tests', t),
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
      for (final q in questions) {
        batch.insert('questions', q.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace);
      }

      final passageData = await passageFuture;
      for (var p in passageData) {
        batch.insert('passages', _sanitizeFor('passages', p),
            conflictAlgorithm: ConflictAlgorithm.replace);
      }

      await Future.wait([
        batch.commit(noResult: true),
        if (imgUrls.isNotEmpty) AppHelperFunctions.downloadImages(imgUrls),
      ]);
    } catch (e) {
      throw AppExceptionHandler.handle(e);
    }
  }

  // ── Delta sync: chapter content ───────────────────────────────────────────

  Future<List<Map<String, dynamic>>> getBySubjectId(
    String table,
    List<String> ids, {
    DateTime? since,
  }) async {
    final sinceIso = since?.toUtc().toIso8601String();

    if (table == 'questions') {
      var q = supabase
          .from('questions')
          .select('*, question_sections(title)')
          .inFilter('subject_id', ids);
      if (sinceIso != null) q = q.gt('updated_at', sinceIso);
      return await q;
    }

    if (table == 'tests') {
      var q = supabase.from('tests').select().inFilter('subject_id', ids);
      if (sinceIso != null) q = q.gt('updated_at', sinceIso);
      return await q;
    }

    // chapters — no updated_at, always full sync (rarely changes)
    return await supabase.from(table).select().inFilter('subject_id', ids);
  }

  Future<List<Map<String, dynamic>>> getPassages(List<int> passageIds) async {
    return await supabase.from('passages').select().inFilter('id', passageIds);
  }

  Future<List<dynamic>> _fetchChangedPassages(
    List<int> passageIds, {
    DateTime? since,
  }) async {
    var q = supabase.from('passages').select().inFilter('id', passageIds);
    if (since != null) {
      q = q.gt('updated_at', since.toUtc().toIso8601String());
    }
    return await q;
  }

  // ── Sanitization ──────────────────────────────────────────────────────────

  static const _knownColumns = <String, Set<String>>{
    'subjects': {'id', 'name', 'is_natural', 'is_common', 'is_downloaded'},
    'chapters': {'id', 'subject_id', 'grade', 'chapter_number', 'title'},
    'tests': {
      'id', 'subject_id', 'grade', 'chapter_id',
      'title', 'type', 'question_count', 'time', 'created_at',
    },
    'passages': {'id', 'content', 'title', 'image_url'},
  };

  static Map<String, dynamic> sanitizeTest(Map<String, dynamic> row) =>
      _sanitizeFor('tests', row);

  static Map<String, dynamic> sanitizePassage(Map<String, dynamic> row) =>
      _sanitizeFor('passages', row);

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
