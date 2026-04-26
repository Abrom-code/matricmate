import 'package:matricmate/data/database/database_service.dart';
import 'package:matricmate/features/exam/models/passage_model.dart';
import 'package:matricmate/features/exam/models/question_model.dart';
import 'package:matricmate/features/exam/models/result_model.dart';
import 'package:matricmate/utils/exceptions/exeption_handler.dart';
import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class QuestionRepository {
  final supabase = Supabase.instance.client;
  final DatabaseService _dbService = DatabaseService.instance;

  Future<List<Map<String, dynamic>>> getQnByTestIdLocal(int testId) async {
    try {
      return await _dbService.getQuestionsByTest(testId);
    } catch (e) {
      throw AppExceptionHandler.handle(e);
    }
  }

  Future<List<Map<String, dynamic>>> getQnByTestIdRemote(int testId) async {
    try {
      return await supabase
          .from('questions')
          .select()
          .eq('test_id', testId)
          .order('question_order');
    } catch (e) {
      throw AppExceptionHandler.handle(e);
    }
  }

  Future<void> addQn(QuestionModel q) async {
    try {
      final db = await _dbService.database;
      await db.insert(
        'questions',
        q.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      throw AppExceptionHandler.handle(e);
    }
  }

  Future<void> saveResult(ResultModel result) async {
    try {
      final db = await _dbService.database;
      await db.insert(
        'results',
        result.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      throw AppExceptionHandler.handle(e);
    }
  }

  Future<PassageModel> getPassage(int pId) async {
    try {
      return await _dbService.getPassage(pId);
    } catch (e) {
      throw AppExceptionHandler.handle(e);
    }
  }
}
