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
  }) async {
    try {
      return await _dbService.getTests(
        subjectId: subjectId,
        grade: grade,
        type: type,
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

  Future<ResultModel?> loadSavedResults(int testId) async {
    try {
      return await _dbService.loadSavedTestResult(testId);
    } catch (e) {
      throw AppExceptionHandler.handle(e);
    }
  }
}
