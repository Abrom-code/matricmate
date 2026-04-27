import 'package:matricmate/data/database/database_service.dart';
import 'package:matricmate/features/exam/models/passage_model.dart';
import 'package:matricmate/features/exam/models/question_model.dart';
import 'package:matricmate/features/exam/models/result_model.dart';
import 'package:matricmate/utils/exceptions/exeption_handler.dart';
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

  Future<void> addQn(QuestionModel q) async {
    try {
      await _dbService.insetData('questions', q.toMap());
    } catch (e) {
      throw AppExceptionHandler.handle(e);
    }
  }

  Future<void> addPassage(PassageModel p) async {
    try {
      await _dbService.insetData('passages', p.toMap());
    } catch (e) {
      throw AppExceptionHandler.handle(e);
    }
  }

  Future<void> saveResult(ResultModel result) async {
    try {
      await _dbService.insetData('results', result.toMap());
    } catch (e) {
      throw AppExceptionHandler.handle(e);
    }
  }

  Future<PassageModel> getLocalPassage(int pId) async {
    try {
      return await _dbService.getPassage(pId);
    } catch (e) {
      throw AppExceptionHandler.handle(e);
    }
  }
}
