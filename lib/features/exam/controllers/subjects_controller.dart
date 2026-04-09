import 'package:get/get.dart';
import 'package:matricmate/data/database/database_service.dart';
import 'package:matricmate/features/exam/models/subject_model.dart';
import 'package:matricmate/utils/logging/logging.dart';
import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SubjectsController extends GetxController {
  static SubjectsController get instance => Get.find();
  final SupabaseClient supabase = Supabase.instance.client;
  final DatabaseService _dbService = DatabaseService.instance;
  final RxBool isLoading = false.obs;
  final RxString selectedStream = "natural".obs;

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

      final response = await supabase.from("subjects").select().order("id");
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
      AppLoggerHelper.error(e.toString());
    } finally {
      isLoading.value = false;
    }
  }
}
