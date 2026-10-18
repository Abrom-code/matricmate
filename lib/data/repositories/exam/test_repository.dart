import 'dart:async';

import 'package:matricmate/data/database/database_service.dart';
import 'package:matricmate/features/exam/models/question_model.dart';
import 'package:matricmate/features/exam/models/result_model.dart';
import 'package:matricmate/features/exam/models/test_model.dart';
import 'package:matricmate/utils/constants/app_timeouts.dart';
import 'package:matricmate/utils/exceptions/exception_handler.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';
import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TestRepository {
  TestRepository({DatabaseService? databaseService, SupabaseClient? supabase})
      : _dbService = databaseService ?? DatabaseService.instance,
        _injectedSupabase = supabase;

  final DatabaseService _dbService;
  final SupabaseClient? _injectedSupabase;

  SupabaseClient get _supabase => _injectedSupabase ?? Supabase.instance.client;

  Future<List<Map<String, dynamic>>> getLocalTests({
    required int subjectId,
    int? grade,
    String? type,
    int? chapterId,
  }) async {
    try {
      return await _dbService.getTests(
        subjectId: subjectId,
        grade: grade,
        type: type,
        chapterId: chapterId,
      );
    } catch (e) {
      throw AppExceptionHandler.handle(e);
    }
  }

  Future<void> addTest(TestModel test) async {
    try {
      await _dbService.insetData('tests', test.toMap());
    } catch (e) {
      throw AppExceptionHandler.handle(e);
    }
  }

  Future<bool> hasQns(int testId) async {
    try {
      return await _dbService.hasQuestions(testId);
    } catch (e) {
      throw AppExceptionHandler.handle(e);
    }
  }

  /// Returns the actual count of questions stored locally for a test.
  Future<int> getActualQuestionCount(int testId) async {
    try {
      final db = await _dbService.database;
      final result = await db.rawQuery(
        'SELECT COUNT(*) as cnt FROM questions WHERE test_id = ?',
        [testId],
      );
      return result.first['cnt'] as int? ?? 0;
    } catch (e) {
      throw AppExceptionHandler.handle(e);
    }
  }

  Future<ResultModel?> loadSavedResults(int testId) async {
    try {
      return await _dbService.loadSavedTestResult(testId);
    } catch (e) {
      throw AppExceptionHandler.handle(e);
    }
  }

  /// Verifies and publishes a draft test to make it available to all students (Admin only).
  Future<bool> verifyAndPublishTest(int testId) async {
    try {
      final res = await _supabase.rpc(
        'verify_and_publish_test',
        params: {'p_test_id': testId},
      );
      return res == true;
    } catch (e) {
      throw AppExceptionHandler.handle(e);
    }
  }

  /// Reverts a test back to draft / verification mode (Admin only).
  Future<bool> unpublishTest(int testId) async {
    try {
      final res = await _supabase.rpc(
        'unpublish_test',
        params: {'p_test_id': testId},
      );
      return res == true;
    } catch (e) {
      throw AppExceptionHandler.handle(e);
    }
  }

  /// Downloads questions, passages, and images for a single test on demand.
  Future<int> downloadTestQuestions(int testId, {int? subjectId}) async {
    try {
      final db = await _dbService.database;

      // 1. Check if questions already exist locally
      final countResult = await db.rawQuery(
        'SELECT COUNT(*) as cnt FROM questions WHERE test_id = ?',
        [testId],
      );
      final existingCount = countResult.first['cnt'] as int? ?? 0;
      if (existingCount > 0) return existingCount;

      // 2. Fetch questions from Supabase
      final response = await _supabase
          .from('questions')
          .select('*, question_sections(title)')
          .eq('test_id', testId)
          .timeout(AppTimeouts.download);

      final questionsData = List<Map<String, dynamic>>.from(response);
      if (questionsData.isEmpty) return 0;

      final Set<int> passageIds = {};
      final Set<String> imgUrls = {};
      final List<QuestionModel> questions = [];

      for (final q in questionsData) {
        final map = Map<String, dynamic>.from(q);
        if (subjectId != null &&
            (map['subject_id'] == null || map['subject_id'] == 0)) {
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

      // 3. Fetch passages if any
      List<dynamic> passageData = [];
      if (passageIds.isNotEmpty) {
        passageData = await _supabase
            .from('passages')
            .select()
            .inFilter('id', passageIds.toList())
            .timeout(AppTimeouts.download);
      }

      // 4. Batch insert into SQLite
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
          Map<String, dynamic>.from(p),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);

      // 5. Download images in background
      if (imgUrls.isNotEmpty) {
        unawaited(AppHelperFunctions.downloadImages(imgUrls));
      }

      return questions.length;
    } catch (e) {
      throw AppExceptionHandler.handle(e);
    }
  }
}
