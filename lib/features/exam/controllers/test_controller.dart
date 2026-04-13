import 'package:get/get.dart';
import 'package:matricmate/data/database/database_service.dart';
import 'package:matricmate/features/exam/models/test_model.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';
import 'package:matricmate/utils/helpers/toast_helper.dart';
import 'package:matricmate/utils/network_manager/network_manager.dart';
import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TestController extends GetxController {
  static TestController get instance => Get.find();

  final SupabaseClient supabaseClient = Supabase.instance.client;
  final DatabaseService _databaseService = DatabaseService.instance;

  final RxList<TestModel> chapterTest = <TestModel>[].obs;
  final RxList<TestModel> allGradeTests = <TestModel>[].obs;
  final RxList<TestModel> singleGradeTests = <TestModel>[].obs;
  final RxMap<int, bool> testHasQuestions = <int, bool>{}.obs;

  @override
  void onInit() {
    final args = Get.arguments;

    int? subjectId;

    if (args is Map) {
      subjectId = args['subject_id'];
    } else if (args is int) {
      subjectId = args;
    } else if (args is String) {
      subjectId = int.tryParse(args);
    }

    if (subjectId != null) {
      loadAllChapterTests(subjectId);
    }

    super.onInit();
  }

  Future<void> loadAllChapterTests(int subjectId) async {
    try {
      chapterTest.clear();
      testHasQuestions.clear();

      final dbChapterTests = await _databaseService.getSubjectTests(subjectId);

      late List<TestModel> data;

      if (dbChapterTests.isNotEmpty) {
        data = dbChapterTests.map((e) => TestModel.fromMap(e)).toList();
      } else {
        final isConnectd = await NetworkManager.instance.isConnected();
        if (!isConnectd) {
          ToastHelper.warning(
            "No Internet!",
            "Please turn on mobile data or connect to WIFI!",
          );
          return;
        }

        final response = await supabaseClient
            .from('tests')
            .select()
            .eq('subject_id', subjectId);

        data = (response as List).map((e) => TestModel.fromJson(e)).toList();

        final db = await _databaseService.database;

        for (final test in data) {
          await db.insert(
            'tests',
            test.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }

      chapterTest.assignAll(data);

      await loadTestQuestionFlags(data);
      loadAllGradeTests();
    } catch (e) {
      AppHelperFuntions.showAlert("Test Error", e.toString());
    }
  }

  Future<void> loadTestQuestionFlags(List<TestModel> tests) async {
    await Future.wait(
      tests.map((test) async {
        final hasQn = await _databaseService.hasQuestions(test.id);
        testHasQuestions[test.id] = hasQn;
      }),
    );
  }

  List<TestModel> getTestsByGradeAndChapter(int? grade, int? chapterId) {
    if (grade == null || chapterId == null) return chapterTest;

    return chapterTest
        .where((e) => e.grade == grade && e.chapterId == chapterId)
        .toList();
  }

  void loadAllGradeTests() {
    allGradeTests.value = chapterTest
        .where((t) => t.type == 'subject')
        .toList();
  }

  void loadGradeTests(int grade) {
    singleGradeTests.value = chapterTest
        .where((t) => t.type == 'grade' && t.grade == grade)
        .toList();
  }

  Future<bool> hasQuestions(int testId) async {
    return await _databaseService.hasQuestions(testId);
  }
}
