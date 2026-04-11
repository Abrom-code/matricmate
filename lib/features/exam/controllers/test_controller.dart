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

  @override
  void onInit() {
    final subjectId = Get.arguments as int?;
    if (subjectId != null) {
      loadAllChapterTests(subjectId);
    }
    super.onInit();
  }

  Future<void> loadAllChapterTests(int subjectId) async {
    try {
      final sub = SubjectsController.instance.subjects.firstWhereOrNull(
        (sub) => sub.id == subjectId,
      );

      if (sub == null) {
        AppHelperFuntions.showAlert("Error", "$subjectId Subject not found");
        return;
      }
      final dbChapterTests = await _databaseService.getSubjectTests(subjectId);
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

  List<TestModel> getTestsByGradeAndChapter(int? grade, int? chapterId) {
    if (grade == null || chapterId == null) return chapterTest;

    return chapterTest.where((e) {
      return e.grade == grade && e.chapterId == chapterId;
    }).toList();
  }
}
