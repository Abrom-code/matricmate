import 'package:matricmate/data/database/database_service.dart';
import 'package:matricmate/features/exam/models/pilot_exam_model.dart';
import 'package:matricmate/features/exam/models/question_model.dart';
import 'package:matricmate/utils/constants/app_timeouts.dart';
import 'package:matricmate/utils/exceptions/exception_handler.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';
import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PilotExamRepository {
  final DatabaseService _dbService = DatabaseService.instance;
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Fetches all active pilot exams from local SQLite.
  Future<List<PilotExamModel>> getLocalPilotExams({bool includeDrafts = false}) async {
    try {
      final db = await _dbService.database;
      final rows = await db.query(
        'pilot_exams',
        where: includeDrafts ? null : 'is_active = 1',
        orderBy: 'id ASC',
      );

      return rows.map((r) => PilotExamModel.fromMap(r)).toList();
    } catch (e) {
      throw AppExceptionHandler.handle(e);
    }
  }

  /// Cleans legacy dummy seeded pilot exams from local SQLite.
  Future<void> clearLegacyDummySeed() async {
    try {
      final db = await _dbService.database;
      await db.delete(
        'pilot_exams',
        where: 'title IN (?, ?)',
        whereArgs: [
          '1st Semester Model Exam',
          'National Pre-Matric Simulation',
        ],
      );
      await db.rawDelete('''
        DELETE FROM pilot_exam_subjects 
        WHERE pilot_exam_id NOT IN (SELECT id FROM pilot_exams)
      ''');
    } catch (_) {}
  }

  /// Fetches the 6 subjects for a pilot exam matching the student's stream.
  Future<List<PilotExamSubjectModel>> getLocalPilotExamSubjects(
    int pilotExamId,
    String stream,
  ) async {
    try {
      final db = await _dbService.database;
      final normalizedStream = stream.toLowerCase().trim();

      final rows = await db.query(
        'pilot_exam_subjects',
        where:
            'pilot_exam_id = ? AND (stream = ? OR stream = "common" OR stream = "both")',
        whereArgs: [pilotExamId, normalizedStream],
        orderBy: 'order_index ASC',
      );

      return rows.map((r) => PilotExamSubjectModel.fromMap(r)).toList();
    } catch (e) {
      throw AppExceptionHandler.handle(e);
    }
  }

  /// Fetches remote pilot exams from Supabase if table exists.
  /// If [includeDrafts] is true, queries all exams (for admin verification mode).
  /// Returns null if query failed (offline or table missing), or List on success.
  Future<List<Map<String, dynamic>>?> fetchRemotePilotExams({
    bool includeDrafts = false,
  }) async {
    try {
      var query = _supabase.from('pilot_exams').select();
      if (!includeDrafts) {
        query = query.eq('is_active', true).eq('status', 'published');
      }
      final response = await query.order('id', ascending: true).timeout(AppTimeouts.query);
      return List<Map<String, dynamic>>.from(response);
    } catch (_) {
      return null;
    }
  }

  /// Verifies and publishes a draft pilot exam (Admin only).
  Future<bool> verifyAndPublishPilotExam(int pilotExamId) async {
    try {
      final res = await _supabase.rpc(
        'verify_and_publish_pilot_exam',
        params: {'p_pilot_exam_id': pilotExamId},
      );
      return res == true;
    } catch (e) {
      throw AppExceptionHandler.handle(e);
    }
  }

  /// Fetches remote subjects for a pilot exam from Supabase.
  /// Returns null if query failed, or List on success.
  Future<List<Map<String, dynamic>>?> fetchRemotePilotExamSubjects(
    int pilotExamId,
  ) async {
    try {
      final response = await _supabase
          .from('pilot_exam_subjects')
          .select()
          .eq('pilot_exam_id', pilotExamId)
          .order('order_index', ascending: true)
          .timeout(AppTimeouts.query);
      return List<Map<String, dynamic>>.from(response);
    } catch (_) {
      return null;
    }
  }

  /// Synchronizes remote pilot exams into local SQLite.
  /// If remote is empty, removes all local pilot exams to reflect Supabase state.
  Future<void> syncPilotExams(List<Map<String, dynamic>> exams) async {
    try {
      final db = await _dbService.database;
      if (exams.isEmpty) {
        await db.delete('pilot_exams');
        await db.delete('pilot_exam_subjects');
        return;
      }

      final remoteIds = exams.map((e) => e['id']).toList();
      final placeholders = List.filled(remoteIds.length, '?').join(',');
      await db.delete(
        'pilot_exams',
        where: 'id NOT IN ($placeholders)',
        whereArgs: remoteIds,
      );

      final batch = db.batch();
      for (final exam in exams) {
        batch.insert(
          'pilot_exams',
          {
            'id': exam['id'],
            'title': exam['title'],
            'description': exam['description'] ?? '',
            'edition': exam['edition'] ?? '2019 E.C.',
            'is_premium': (exam['is_premium'] == null ||
                    exam['is_premium'] == true ||
                    exam['is_premium'] == 1 ||
                    exam['is_premium'] == '1')
                ? 1
                : 0,
            'is_active': (exam['is_active'] == true || exam['is_active'] == 1) ? 1 : 0,
            'status': exam['status']?.toString() ??
                ((exam['is_active'] == true || exam['is_active'] == 1) ? 'published' : 'draft'),
            'created_at': exam['created_at'],
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    } catch (_) {}
  }

  /// Saves remote pilot exams batch into SQLite (alias for syncPilotExams).
  Future<void> savePilotExamsBatch(List<Map<String, dynamic>> exams) =>
      syncPilotExams(exams);

  /// Synchronizes remote subjects for an exam into local SQLite.
  Future<void> syncPilotExamSubjects(
    int examId,
    List<Map<String, dynamic>> subjects,
  ) async {
    try {
      final db = await _dbService.database;
      if (subjects.isEmpty) {
        await db.delete(
          'pilot_exam_subjects',
          where: 'pilot_exam_id = ?',
          whereArgs: [examId],
        );
        return;
      }

      final remoteIds = subjects.map((s) => s['id']).toList();
      final placeholders = List.filled(remoteIds.length, '?').join(',');
      await db.delete(
        'pilot_exam_subjects',
        where: 'pilot_exam_id = ? AND id NOT IN ($placeholders)',
        whereArgs: [examId, ...remoteIds],
      );

      final batch = db.batch();
      for (final s in subjects) {
        batch.insert(
          'pilot_exam_subjects',
          {
            'id': s['id'],
            'pilot_exam_id': s['pilot_exam_id'],
            'subject_id': s['subject_id'],
            'subject_name': s['subject_name'] ?? 'Subject',
            'stream': (s['stream'] as String?)?.toLowerCase() ?? 'natural',
            'test_id': s['test_id'],
            'order_index': s['order_index'] ?? 1,
            'question_count': s['question_count'] ?? 60,
            'time_minutes': s['time_minutes'] ?? 90,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    } catch (_) {}
  }

  /// Saves remote pilot exam subjects batch into SQLite (alias for syncPilotExamSubjects).
  Future<void> savePilotExamSubjectsBatch(
    List<Map<String, dynamic>> subjects,
  ) async {
    if (subjects.isEmpty) return;
    final examId = subjects.first['pilot_exam_id'] as int? ?? 0;
    if (examId > 0) {
      await syncPilotExamSubjects(examId, subjects);
    }
  }

  /// Downloads questions, reading passages, and diagrams for a given subject test from Supabase
  /// and saves them into local SQLite.
  Future<int> downloadSubjectQuestions(
    int testId,
    int subjectId, {
    void Function(String step, double progress)? onStep,
  }) async {
    try {
      final db = await _dbService.database;

      // 1. Check if questions already exist in SQLite
      final countResult = await db.rawQuery(
        'SELECT COUNT(*) as cnt FROM questions WHERE test_id = ?',
        [testId],
      );
      final existingCount = countResult.first['cnt'] as int? ?? 0;
      if (existingCount > 0) {
        onStep?.call('Ready', 1.0);
        return existingCount;
      }

      // 2. Fetch questions from Supabase
      onStep?.call('Fetching questions…', 0.2);
      final response = await _supabase
          .from('questions')
          .select('*, question_sections(title)')
          .eq('test_id', testId)
          .timeout(AppTimeouts.download);

      final questionsData = List<Map<String, dynamic>>.from(response);

      if (questionsData.isEmpty) {
        // Fallback: check if any questions exist locally for this test or subject
        final fallbackLocal = await db.rawQuery(
          'SELECT COUNT(*) as cnt FROM questions WHERE test_id = ? OR subject_id = ?',
          [testId, subjectId],
        );
        return fallbackLocal.first['cnt'] as int? ?? 0;
      }

      final Set<int> passageIds = {};
      final Set<String> imgUrls = {};
      final List<QuestionModel> questions = [];

      for (final q in questionsData) {
        final map = Map<String, dynamic>.from(q);
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

      // 3. Fetch passages if needed
      List<dynamic> passageData = [];
      if (passageIds.isNotEmpty) {
        onStep?.call('Fetching passages…', 0.5);
        final pResponse = await _supabase
            .from('passages')
            .select()
            .inFilter('id', passageIds.toList())
            .timeout(AppTimeouts.download);
        passageData = List<dynamic>.from(pResponse);
      }

      // 4. Write to SQLite in a single transaction
      onStep?.call('Saving to device…', 0.7);
      final batch = db.batch();
      for (final q in questions) {
        batch.insert(
          'questions',
          q.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      for (final p in passageData) {
        batch.insert(
          'passages',
          Map<String, dynamic>.from(p as Map),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);

      // 5. Download diagrams / images
      if (imgUrls.isNotEmpty) {
        onStep?.call('Downloading diagrams…', 0.85);
        await AppHelperFunctions.downloadImages(
          imgUrls,
          onProgress:
              (p) => onStep?.call('Downloading diagrams…', 0.85 + (p * 0.15)),
        );
      }

      onStep?.call('Done', 1.0);
      return questions.length;
    } catch (e) {
      throw AppExceptionHandler.handle(e);
    }
  }

  /// Deletes downloaded questions for the given test IDs from local SQLite.
  Future<void> deleteExamQuestions(List<int> testIds) async {
    if (testIds.isEmpty) return;
    try {
      final db = await _dbService.database;
      final placeholders = List.filled(testIds.length, '?').join(',');
      await db.delete(
        'questions',
        where: 'test_id IN ($placeholders)',
        whereArgs: testIds,
      );
    } catch (e) {
      throw AppExceptionHandler.handle(e);
    }
  }
}
