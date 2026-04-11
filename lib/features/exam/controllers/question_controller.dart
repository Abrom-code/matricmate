import 'package:get/get.dart';
import 'package:matricmate/data/database/database_service.dart';
import 'package:matricmate/features/exam/models/question_model.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';
import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class QuestionController extends GetxController {
  static QuestionController get instance => Get.find();

  final SupabaseClient supabase = Supabase.instance.client;
  final DatabaseService _databaseService = DatabaseService.instance;

  final RxList<QuestionModel> testQuestions = <QuestionModel>[].obs;

  Future<void> loadTestQuestions(int testId) async {
    try {
      final dbQuestions = await _databaseService.getQuestionsByTest(testId);

      if (dbQuestions.isNotEmpty) {
        testQuestions.assignAll(
          dbQuestions.map((e) => QuestionModel.fromMap(e)).toList(),
        );
        return;
      }

      final response = await supabase
          .from('questions')
          .select()
          .eq('test_id', testId);

      final data = (response as List)
          .map((e) => QuestionModel.fromJson(e))
          .toList();

      testQuestions.assignAll(data);

      final db = await _databaseService.database;

      for (final q in data) {
        await db.insert(
          'questions',
          q.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    } catch (e) {
      AppHelperFuntions.showAlert("Question Error", e.toString());
    }
  }
}
