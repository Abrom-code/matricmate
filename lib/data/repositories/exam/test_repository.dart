import 'package:matricmate/data/database/database_service.dart';
import 'package:matricmate/features/exam/models/result_model.dart';
import 'package:matricmate/features/exam/models/test_model.dart';
import 'package:matricmate/utils/exceptions/exception_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TestRepository {
  TestRepository({DatabaseService? databaseService, SupabaseClient? supabase})
      : _dbService = databaseService ?? DatabaseService.instance,
        _supabase = supabase ?? Supabase.instance.client;

  final DatabaseService _dbService;
  final SupabaseClient _supabase;

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
}
