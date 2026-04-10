import 'package:get/get.dart';
import 'package:matricmate/data/database/database_service.dart';
import 'package:matricmate/features/exam/controllers/subjects_controller.dart';
import 'package:matricmate/features/exam/models/test_model.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';
import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TestController extends GetxController {
  static TestController get instance => Get.find();
  final SupabaseClient supabaseClient = Supabase.instance.client;
  final DatabaseService _databaseService = DatabaseService.instance;

  final RxList<TestModel> chapterTest = <TestModel>[].obs;

  Future<void> loadAllChapterTests(String subject) async {
    try {
      final sub = SubjectsController.instance.subjects
          .where((sub) => sub.name == subject)
          .first;
      final dbChapterTests = await _databaseService.getSubjectTests(subject);
      if (dbChapterTests.isNotEmpty) {
        chapterTest.value = dbChapterTests
            .map((map) => TestModel.fromMap(map))
            .toList();
        return;
      }

      final response = await supabaseClient
          .from('tests')
          .select()
          .filter('subject_id', 'eq', sub.id);
      final data = (response as List<dynamic>)
          .map((json) => TestModel.fromJson(json))
          .toList();

      chapterTest.value = data;

      final db = await _databaseService.database;
      for (final test in data) {
        await db.insert(
          'tests',
          test.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    } on Exception catch (e) {
      AppHelperFuntions.showAlert("Test Error", e.toString());
    }
  }
}
