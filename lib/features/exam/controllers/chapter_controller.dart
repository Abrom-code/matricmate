import 'package:get/get.dart';
import 'package:matricmate/data/database/database_service.dart';
import 'package:matricmate/features/exam/models/chapter_model.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';
import 'package:matricmate/utils/helpers/toast_helper.dart';
import 'package:matricmate/utils/network_manager/network_manager.dart';
import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChapterController extends GetxController {
  static ChapterController get instance => Get.find();

  final SupabaseClient supabase = Supabase.instance.client;
  final DatabaseService _databaseService = DatabaseService.instance;

  final RxList<ChapterModel> subjectChapters = <ChapterModel>[].obs;

  final RxMap<int, bool> chapterHasTests = <int, bool>{}.obs;

  final RxBool isChapterLoading = false.obs;

  @override
  void onInit() {
    super.onInit();

    final subjectId = Get.arguments;

    if (subjectId != null) {
      loadSubjectChapters(subjectId);
    }
  }

  Future<void> loadSubjectChapters(int subjectId) async {
    try {
      isChapterLoading.value = true;
      subjectChapters.clear();
      chapterHasTests.clear();

      List<ChapterModel> data = [];

      final dbChapters = await _databaseService.getSubjectChapters(subjectId);

      if (dbChapters.isNotEmpty) {
        data = dbChapters.map((e) => ChapterModel.fromMap(e)).toList();
      } else {
        final isConnectd = await NetworkManager.instance.isConnected();
        if (!isConnectd) {
          ToastHelper.warning(
            "No Internet!",
            "Please turn on mobile data or connect to WIFI!",
          );
          return;
        }

        final response = await supabase
            .from('chapters')
            .select()
            .eq('subject_id', subjectId);

        data = (response as List).map((e) => ChapterModel.fromJson(e)).toList();

        final db = await _databaseService.database;

        for (final chapter in data) {
          await db.insert(
            'chapters',
            chapter.toMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }

      subjectChapters.assignAll(data);

      // load flags AFTER chapters
      await loadChapterTestFlags(data);
    } catch (e) {
      AppHelperFuntions.showAlert("Chapter Error", e.toString());
    } finally {
      isChapterLoading.value = false;
    }
  }

  List<ChapterModel> getChaptersByGrade(int? grade) {
    if (grade == null) return subjectChapters;
    return subjectChapters.where((e) => e.grade == grade).toList();
  }

  Future<void> loadChapterTestFlags(List<ChapterModel> chapters) async {
    await Future.wait(
      chapters.map((chapter) async {
        final hasTests = await _databaseService.hasTests(chapter.id);

        chapterHasTests[chapter.id] = hasTests;
      }),
    );
  }
}
