import 'package:matricmate/data/database/database_service.dart';
import 'package:matricmate/features/exam/models/result_model.dart';
import 'package:matricmate/features/exam/models/test_model.dart';
import 'package:matricmate/utils/exceptions/exeption_handler.dart';

class TestRepository {
  final DatabaseService _dbService = DatabaseService.instance;

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

  /// Returns the actual number of questions stored locally for a test.
  /// Use this instead of [TestModel.questionCount] which comes from Supabase
  /// and may be stale or incorrect.
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
}
