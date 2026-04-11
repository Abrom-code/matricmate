import 'package:get/get.dart';
import 'package:matricmate/data/database/database_service.dart';
import 'package:matricmate/features/exam/controllers/chapter_controller.dart';
import 'package:matricmate/features/exam/controllers/question_controller.dart';
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
  final RxBool isRefreshing = false.obs;
  final RxString selectedStream = "natural".obs;
  final RxMap<String, bool> downloadingMap = <String, bool>{}.obs;

  var subjects = <SubjectMoModel>[].obs;

  Future<void> loadSubjects() async {
    try {
      isLoading.value = true;

      final dbSubjects = await _dbService.getSubjects();
      if (dbSubjects.isNotEmpty) {
        subjects.value = dbSubjects
            .map((subject) => SubjectMoModel.fromMap(subject))
            .toList();
        return;
      }

      final response = await supabase.from("subjects").select();
      final data = (response as List<dynamic>)
          .map((e) => SubjectMoModel.fromJson(e))
          .toList();

      subjects.value = data;

      final db = await _dbService.database;
      for (var subject in data) {
        await db.insert(
          'subjects',
          subject.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    } on Exception catch (e) {
      AppHelperFuntions.showAlert("Subject Error", e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> downloadSubject(String subject, int subjectId) async {
    try {
      final chapterController = Get.put(ChapterController());
      final testController = Get.put(TestController());
      final questionController = Get.put(QuestionController());

      downloadingMap[subject] = true;
      await chapterController.loadSubjectChapters(subject);
      await testController.loadAllChapterTests(subjectId);
      await questionController.loadSubjectQuestions(subject);

      final db = await _dbService.database;
      await db.update(
        'subjects',
        {'is_downloaded': '1'},
        where: 'name = ?',
        whereArgs: [subject],
      );
      SubjectsController.instance.loadSubjects();
    } catch (e) {
      AppHelperFuntions.showAlert("Subject Download Error", e.toString());
    } finally {
      downloadingMap[subject] = false;
    }
  }

  Future<void> syncSubjects() async {
    try {
      isRefreshing.value = true;

      final localSubjects = await _dbService.getSubjects();

      final remoteSubjects = await supabase
          .from("subjects")
          .select()
          .order("id");

      final remote = (remoteSubjects as List<dynamic>)
          .map((e) => SubjectMoModel.fromJson(e))
          .toList();

      final db = await _dbService.database;

      // UPSERT (insert/update)
      for (final s in remote) {
        final local = localSubjects.where((sub) => sub['id'] == s.id);

        if (local.isEmpty) {
          await db.insert('subjects', s.toMap());
        } else {
          final localData = local.first;

          await db.update(
            'subjects',
            {...s.toMap(), 'is_downloaded': localData['is_downloaded']},
            where: 'id = ?',
            whereArgs: [s.id],
          );
        }
      }

      //  DELETE missing subjects
      final remoteIds = remote.map((e) => e.id).toSet();
      final localIds = localSubjects.map((e) => e['id']).toSet();

      final toDelete = localIds.difference(remoteIds);

      for (final id in toDelete) {
        await db.delete('subjects', where: 'id = ?', whereArgs: [id]);
      }

      loadSubjects();
    } catch (e) {
      AppHelperFuntions.showAlert("Sync Error", e.toString());
    } finally {
      isRefreshing.value = false;
    }
  }
}
