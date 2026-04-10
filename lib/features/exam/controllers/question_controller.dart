import 'package:get/get.dart';
import 'package:matricmate/data/database/database_service.dart';
import 'package:matricmate/features/exam/controllers/subjects_controller.dart';
import 'package:matricmate/features/exam/models/question_model.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';
import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class QuestionController extends GetxController {
  static QuestionController get instance => Get.find();
  final SupabaseClient supabase = Supabase.instance.client;
  final DatabaseService _databaseService = DatabaseService.instance;

  final subjectQuestions = <QuestionModel>[].obs;

  Future<void> loadSubjectQuestions(String subject) async {
    try {
      final sub = SubjectsController.instance.subjects.firstWhere(
        (sub) => sub.name == subject,
      );
      final dbCourseQuestions = await _databaseService.getAllSubjectQuestions(
        subject,
      );
      if (dbCourseQuestions.isNotEmpty) {
        subjectQuestions.value = dbCourseQuestions
            .map((e) => QuestionModel.fromMap(e))
            .toList();
        return;
      }

      final response = await supabase
          .from('questions')
          .select()
          .filter('subject_id', 'eq', sub.id);

      final data = (response as List<dynamic>)
          .map((e) => QuestionModel.fromJson(e))
          .toList();

      subjectQuestions.value = data;

      final db = await _databaseService.database;
      for (var chapter in data) {
        await db.insert(
          'questions',
          chapter.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    } catch (e) {
      AppHelperFuntions.showAlert("Question Error", e.toString());
    }
  }
}
