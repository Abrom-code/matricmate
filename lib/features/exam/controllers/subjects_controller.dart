import 'package:get/get.dart';
import 'package:matricmate/data/database/database_service.dart';
import 'package:matricmate/features/exam/controllers/chapter_controller.dart';
import 'package:matricmate/features/exam/controllers/test_controller.dart';
import 'package:matricmate/features/exam/models/subject_model.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';
import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SubjectsController extends GetxController {
  static SubjectsController get instance => Get.find();

  final SupabaseClient supabase = Supabase.instance.client;
  final DatabaseService _dbService = DatabaseService.instance;

  final RxBool isLoading = false.obs;
  final RxBool isDownloading = false.obs;

  final RxString selectedStream = "natural".obs;

  final RxMap<String, bool> downloadingMap = <String, bool>{}.obs;

  final RxList<SubjectMoModel> subjects = <SubjectMoModel>[].obs;

  /// LOAD SUBJECTS

  Future<void> loadSubjects() async {
    try {
      isLoading.value = true;

      final dbSubjects = await _dbService.getSubjects();

      if (dbSubjects.isNotEmpty) {
        subjects.assignAll(
          dbSubjects.map((e) => SubjectMoModel.fromMap(e)).toList(),
        );
        return;
      }

      final response = await supabase.from("subjects").select();

      final data = (response as List)
          .map((e) => SubjectMoModel.fromJson(e))
          .toList();

      subjects.assignAll(data);

      final db = await _dbService.database;

      for (final subject in data) {
        await db.insert(
          'subjects',
          subject.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    } catch (e) {
      AppHelperFuntions.showAlert("Subject Error", e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  /// DOWNLOAD SUBJECT (FIXED)
  Future<void> downloadSubject(String subject, int subjectId) async {
    try {
      downloadingMap[subject] = true;
      final chapterController = Get.find<ChapterController>();
      final testController = Get.find<TestController>();

      ///  Load chapters
      await chapterController.loadSubjectChapters(subjectId);

      ///  Load tests
      await testController.loadAllChapterTests(subjectId);

      /// Mark as downloaded in DB
      final db = await _dbService.database;

      await db.update(
        'subjects',
        {'is_downloaded': 1},
        where: 'name = ?',
        whereArgs: [subject],
      );

      /// 4. Refresh subjects
      await loadSubjects();
    } catch (e) {
      AppHelperFuntions.showAlert("Subject Download Error", e.toString());
    } finally {
      downloadingMap[subject] = false;
    }
  }

  List<SubjectMoModel> get filteredSubjects {
    final isNatural = selectedStream.value == "natural";

    return subjects.where((subject) {
      return subject.isCommon || subject.isNatural == (isNatural ? 1 : 0);
    }).toList();
  }
}
