import 'package:matricmate/data/database/database_service.dart';
import 'package:matricmate/features/exam/models/pilot_exam_model.dart';
import 'package:matricmate/utils/constants/app_timeouts.dart';
import 'package:matricmate/utils/exceptions/exception_handler.dart';
import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PilotExamRepository {
  final DatabaseService _dbService = DatabaseService.instance;
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Fetches all active pilot exams from local SQLite.
  Future<List<PilotExamModel>> getLocalPilotExams() async {
    try {
      final db = await _dbService.database;
      final rows = await db.query(
        'pilot_exams',
        where: 'is_active = 1',
        orderBy: 'id ASC',
      );

      if (rows.isEmpty) {
        // Seed default local sets if empty so user can test right away
        await _seedDefaults(db);
        final seeded = await db.query(
          'pilot_exams',
          where: 'is_active = 1',
          orderBy: 'id ASC',
        );
        return seeded.map((r) => PilotExamModel.fromMap(r)).toList();
      }

      return rows.map((r) => PilotExamModel.fromMap(r)).toList();
    } catch (e) {
      throw AppExceptionHandler.handle(e);
    }
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
  Future<List<Map<String, dynamic>>> fetchRemotePilotExams() async {
    try {
      final response = await _supabase
          .from('pilot_exams')
          .select()
          .eq('is_active', true)
          .order('id', ascending: true)
          .timeout(AppTimeouts.query);
      return List<Map<String, dynamic>>.from(response);
    } catch (_) {
      return [];
    }
  }

  /// Fetches remote subjects for a pilot exam from Supabase.
  Future<List<Map<String, dynamic>>> fetchRemotePilotExamSubjects(
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
      return [];
    }
  }

  /// Saves remote pilot exams batch into SQLite.
  Future<void> savePilotExamsBatch(List<Map<String, dynamic>> exams) async {
    if (exams.isEmpty) return;
    try {
      final db = await _dbService.database;
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
            'created_at': exam['created_at'],
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    } catch (_) {}
  }

  /// Saves remote pilot exam subjects batch into SQLite.
  Future<void> savePilotExamSubjectsBatch(
    List<Map<String, dynamic>> subjects,
  ) async {
    if (subjects.isEmpty) return;
    try {
      final db = await _dbService.database;
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

  /// Seeds default pilot exams and subjects so the user can test the feature immediately.
  Future<void> _seedDefaults(Database db) async {
    try {
      // 1. Seed pilot exam
      await db.insert(
        'pilot_exams',
        {
          'id': 1,
          'title': '1st Semester Model Exam',
          'description':
              'Full-length nationwide pre-matric trial covering all 6 curriculum subjects.',
          'edition': '2019 E.C.',
          'is_premium': 1,
          'is_active': 1,
          'created_at': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      await db.insert(
        'pilot_exams',
        {
          'id': 2,
          'title': 'National Pre-Matric Simulation',
          'description':
              'Authentic NEAEA standard simulation with timed test protocols.',
          'edition': '2019 E.C.',
          'is_premium': 1,
          'is_active': 1,
          'created_at': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // Check existing subjects to link realistic subject IDs
      final existingSubjects = await db.query('subjects');
      final subjectMap = {
        for (final s in existingSubjects)
          (s['name'] as String).toLowerCase(): s['id'] as int,
      };

      // Check existing entrance/model tests to link test IDs
      final existingTests = await db.query('tests');
      final testBySubject = <int, int>{};
      for (final t in existingTests) {
        final subId = t['subject_id'] as int;
        if (!testBySubject.containsKey(subId)) {
          testBySubject[subId] = t['id'] as int;
        }
      }

      // 4 Natural Subjects + 2 Common Subjects = 6
      final naturalList = [
        {'name': 'Mathematics', 'stream': 'natural', 'order': 1},
        {'name': 'Physics', 'stream': 'natural', 'order': 2},
        {'name': 'Chemistry', 'stream': 'natural', 'order': 3},
        {'name': 'Biology', 'stream': 'natural', 'order': 4},
        {'name': 'English', 'stream': 'common', 'order': 5},
        {'name': 'Aptitude', 'stream': 'common', 'order': 6},
      ];

      // 4 Social Subjects (English & Aptitude shared as common)
      final socialList = [
        {'name': 'Mathematics', 'stream': 'social', 'order': 1},
        {'name': 'History', 'stream': 'social', 'order': 2},
        {'name': 'Geography', 'stream': 'social', 'order': 3},
        {'name': 'Economics', 'stream': 'social', 'order': 4},
      ];

      int subjectIndex = 1;
      final batch = db.batch();

      // Seed for Exam 1 & 2
      for (final examId in [1, 2]) {
        for (var i = 0; i < naturalList.length; i++) {
          final item = naturalList[i];
          final name = item['name'] as String;
          final subId = subjectMap[name.toLowerCase()] ?? (i + 1);
          final testId = testBySubject[subId] ?? subId;

          batch.insert(
            'pilot_exam_subjects',
            {
              'id': subjectIndex++,
              'pilot_exam_id': examId,
              'subject_id': subId,
              'subject_name': name,
              'stream': item['stream'] as String,
              'test_id': testId,
              'order_index': item['order'] as int,
              'question_count': 60,
              'time_minutes': 90,
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }

        for (var i = 0; i < socialList.length; i++) {
          final item = socialList[i];
          final name = item['name'] as String;
          final subId = subjectMap[name.toLowerCase()] ?? (i + 10);
          final testId = testBySubject[subId] ?? subId;

          batch.insert(
            'pilot_exam_subjects',
            {
              'id': subjectIndex++,
              'pilot_exam_id': examId,
              'subject_id': subId,
              'subject_name': name,
              'stream': 'social',
              'test_id': testId,
              'order_index': item['order'] as int,
              'question_count': 60,
              'time_minutes': 90,
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }

      await batch.commit(noResult: true);
    } catch (_) {}
  }
}
