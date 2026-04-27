import 'package:get/get.dart';
import 'package:matricmate/data/repositories/exam/chapter_repository.dart';
import 'package:matricmate/features/exam/models/chapter_model.dart';
import 'package:matricmate/utils/exceptions/app_failure_model.dart';
import 'package:matricmate/utils/helpers/toast_helper.dart';

class ChapterController extends GetxController {
  static ChapterController get instance => Get.find();
  final ChapterRepository _repo = ChapterRepository();

  final RxList<ChapterModel> subjectChapters = <ChapterModel>[].obs;

  final RxMap<int, bool> chapterHasTests = <int, bool>{}.obs;

  final RxBool isChapterLoading = false.obs;

  late String title;
  late int subjectId;

  @override
  void onInit() {
    super.onInit();

    title = Get.arguments['title'] ?? 'Default Title';
    subjectId = Get.arguments['id'] ?? 0;

    loadSubjectChapters(subjectId);
  }

  Future<void> loadSubjectChapters(int subjectId) async {
    try {
      isChapterLoading.value = true;
      subjectChapters.clear();
      chapterHasTests.clear();

      List<ChapterModel> data = [];

      final dbChapters = await _repo.getSubjectChaptersById(subjectId);

      data = dbChapters.map((e) => ChapterModel.fromMap(e)).toList();

      subjectChapters.assignAll(data);

      // load flags AFTER chapters
      await loadChapterTestFlags(data);
    } catch (e) {
      if (e is AppFailure) {
        ToastHelper.error(e.title, e.message);
      } else {
        ToastHelper.error("Unexpected Error", e.toString());
      }
    } finally {
      isChapterLoading.value = false;
    }
  }

  List<ChapterModel> getChaptersByGrade(int? grade) {
    if (grade == null) return subjectChapters;
    return subjectChapters.where((e) => e.grade == grade).toList();
  }

  Future<void> loadChapterTestFlags(List<ChapterModel> chapters) async {
    try {
      await Future.wait(
        chapters.map((chapter) async {
          final hasTests = await _repo.hasTests(chapter.id);

          chapterHasTests[chapter.id] = hasTests;
        }),
      );
    } catch (e) {
      if (e is AppFailure) {
        ToastHelper.error(e.title, e.message);
      } else {
        ToastHelper.error("Unexpected Error", e.toString());
      }
    }
  }
}
