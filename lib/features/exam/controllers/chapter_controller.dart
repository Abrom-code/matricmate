import 'package:get/get.dart';
import 'package:matricmate/data/database/database_service.dart';
import 'package:matricmate/features/exam/controllers/subjects_controller.dart';
import 'package:matricmate/features/exam/models/chapter_model.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';
import 'package:matricmate/utils/logging/logging.dart';
import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChapterController extends GetxController {
  static ChapterController get instance => Get.find();

  final SupabaseClient supabase = Supabase.instance.client;
  final DatabaseService _databaseService = DatabaseService.instance;

  final subjectChapters = <ChapterModel>[].obs;

  @override
  void onInit() {
    super.onInit();

    final subject = Get.arguments as String?;
    if (subject != null) {
      loadSubjectChapters(subject);
    }
  }

  Future<void> loadSubjectChapters(String subject) async {
    try {
      final sub = SubjectsController.instance.subjects.firstWhere(
        (sub) => sub.name == subject,
      );

      final dbCourseChapters = await _databaseService.getSubjectChapters(
        subject,
      );

      if (dbCourseChapters.isNotEmpty) {
        subjectChapters.value = dbCourseChapters
            .map((e) => ChapterModel.fromMap(e))
            .toList();
        AppLoggerHelper.debug(dbCourseChapters.toString());
        return;
      }

      final response = await supabase
          .from('chapters')
          .select()
          .eq('subject_id', sub.id!);

      final data = (response as List<dynamic>)
          .map((e) => ChapterModel.fromJson(e))
          .toList();

      subjectChapters.value = data;

      final db = await _databaseService.database;
      for (final chapter in data) {
        await db.insert(
          'chapters',
          chapter.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    } catch (e) {
      AppHelperFuntions.showAlert("Chapter Error", e.toString());
    }
  }

  List<ChapterModel> selectedGradeChapters(int? grade) {
    if (grade == null) return subjectChapters;
    return subjectChapters.where((e) => e.grade == grade).toList();
  }

  List<ChapterModel> getChaptersByGrade(int? grade) {
    if (grade == null) return subjectChapters;
    return subjectChapters.where((e) => e.grade == grade).toList();
  }
}
