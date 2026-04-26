import 'package:matricmate/data/database/database_service.dart';
import 'package:matricmate/features/exam/models/result_model.dart';
import 'package:matricmate/features/exam/models/test_model.dart';
import 'package:matricmate/utils/exceptions/exeption_handler.dart';
import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TestRepository {
  final supabase = Supabase.instance.client;
  final DatabaseService _dbService = DatabaseService.instance;

  Future<List<Map<String, dynamic>>> getLocalTestsById(int subjectId) async {
    try {
      return _dbService.getSubjectTests(subjectId);
    } catch (e) {
      throw AppExceptionHandler.handle(e);
    }
  }

  Future<List<Map<String, dynamic>>> getRemoteTestsById(int subjectId) async {
    try {
      return await supabase.from('tests').select().eq('subject_id', subjectId);
    } catch (e) {
      throw AppExceptionHandler.handle(e);
    }
  }

  Future<void> addTest(TestModel test) async {
    try {
      final db = await _dbService.database;
      await db.insert(
        'tests',
        test.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
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
