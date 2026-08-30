import 'package:get/get.dart';
import 'package:matricmate/data/repositories/exam/chapter_repository.dart';
import 'package:matricmate/features/exam/models/chapter_model.dart';
import 'package:matricmate/features/exam/models/chapter_progress_model.dart';
import 'package:matricmate/utils/exceptions/exception_handler.dart';

class ChapterController extends GetxController {
  static ChapterController get instance => Get.find();
  final ChapterRepository _repo = ChapterRepository();

  final RxList<ChapterModel> subjectChapters = <ChapterModel>[].obs;

  final RxMap<int, bool> chapterHasTests = <int, bool>{}.obs;
  final RxMap<int, ChapterProgressModel> chapterProgress =
      <int, ChapterProgressModel>{}.obs;
  final RxMap<int, ChapterProgressModel> gradeTestProgress =
      <int, ChapterProgressModel>{}.obs;

  final RxBool isChapterLoading = false.obs;

  late String title;
  late int subjectId;
  late bool isCommon;

  @override
  void onInit() {
    super.onInit();

    final args = Get.arguments ?? {};
    title = args['title'] ?? 'Default Title';
    subjectId = args['id'] ?? 0;
    isCommon = args['is_common'] == true ||
        title.toLowerCase() == 'sat' ||
        title.toLowerCase() == 'english';

    loadSubjectChapters(subjectId);
  }

  Future<void> loadSubjectChapters(int subjectId) async {
    try {
      isChapterLoading.value = true;
      subjectChapters.clear();
      chapterHasTests.clear();
      chapterProgress.clear();
      gradeTestProgress.clear();

      List<ChapterModel> data = [];

      final dbChapters = await _repo.getSubjectChaptersById(subjectId);

      data = dbChapters.map((e) => ChapterModel.fromMap(e)).toList();

      subjectChapters.assignAll(data);

      // load flags and progress AFTER chapters
      await Future.wait([
        loadChapterTestFlags(data),
        loadChapterProgress(subjectId),
        loadGradeTestProgress(subjectId),
      ]);
    } catch (e) {
      AppExceptionHandler.handleResponse(e);
    } finally {
      isChapterLoading.value = false;
    }
  }

  Future<void> refreshAllProgress() async {
    await Future.wait([
      loadChapterProgress(subjectId),
      loadGradeTestProgress(subjectId),
    ]);
  }

  Future<void> loadChapterProgress(int subjectId) async {
    try {
      final rows = await _repo.getChapterProgress(subjectId);
      final Map<int, ChapterProgressModel> map = {};
      for (final r in rows) {
        final model = ChapterProgressModel.fromMap(r);
        map[model.chapterId] = model;
      }
      chapterProgress.assignAll(map);
    } catch (_) {
      // Non-fatal, progress falls back to 0
    }
  }

  Future<void> loadGradeTestProgress(int subjectId) async {
    try {
      final rows = await _repo.getGradeTestProgress(subjectId);
      final Map<int, ChapterProgressModel> map = {};
      for (final r in rows) {
        final grade = r['grade'] as int? ?? 9;
        map[grade] = ChapterProgressModel.fromMap(r);
      }
      gradeTestProgress.assignAll(map);
    } catch (_) {
      // Non-fatal
    }
  }

  List<ChapterModel> get allSections => subjectChapters;

  List<ChapterModel> getChaptersByGrade(int? grade) {
    if (grade == null || isCommon) return subjectChapters;
    return subjectChapters.where((e) => e.grade == grade).toList();
  }

  /// Calculates overall summary for a grade tab
  GradeProgressSummary getGradeProgress(int grade) {
    final chapters = getChaptersByGrade(grade);
    int total = 0;
    int completed = 0;
    int inProgress = 0;

    for (final c in chapters) {
      final p = chapterProgress[c.id];
      if (p != null) {
        total += p.totalTests;
        completed += p.completedTests;
        inProgress += p.inProgressTests;
      }
    }

    return GradeProgressSummary(
      totalTests: total,
      completedTests: completed,
      inProgressTests: inProgress,
      totalChapters: chapters.length,
      completedChapters: chapters
          .where((c) => chapterProgress[c.id]?.isCompleted == true)
          .length,
    );
  }

  /// Calculates overall summary for common subjects (SAT & English)
  GradeProgressSummary get overallSectionsProgress {
    int total = 0;
    int completed = 0;
    int inProgress = 0;

    for (final c in subjectChapters) {
      final p = chapterProgress[c.id];
      if (p != null) {
        total += p.totalTests;
        completed += p.completedTests;
        inProgress += p.inProgressTests;
      }
    }

    return GradeProgressSummary(
      totalTests: total,
      completedTests: completed,
      inProgressTests: inProgress,
      totalChapters: subjectChapters.length,
      completedChapters: subjectChapters
          .where((c) => chapterProgress[c.id]?.isCompleted == true)
          .length,
    );
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
      AppExceptionHandler.handleResponse(e);
    }
  }
}
