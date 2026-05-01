import 'package:get/get.dart';
import 'package:matricmate/data/repositories/exam/test_repository.dart';
import 'package:matricmate/features/exam/models/result_model.dart';
import 'package:matricmate/features/exam/models/test_model.dart';
import 'package:matricmate/utils/exceptions/exeption_handler.dart';

class ChapterTestController extends GetxController {
  static ChapterTestController get instance => Get.find();
  final TestRepository _testRepository = TestRepository();
  final RxList<TestModel> chapterTest = <TestModel>[].obs;
  final RxMap<int, bool> testHasQuestions = <int, bool>{}.obs;
  final RxMap<int, ResultModel> testResults = <int, ResultModel>{}.obs;

  final RxString title = ''.obs;
  final RxInt subjectId = 0.obs;
  final RxInt grade = 9.obs;
  final RxInt chapterId = 0.obs;
  final RxString chapter = ''.obs;
  final RxInt chapterNumber = 0.obs;

  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    final args = Get.arguments ?? {};

    title.value = args['subject'] ?? '';
    subjectId.value = args['subject_id'] ?? 0;
    chapter.value = args['chapter'] ?? '';
    chapterId.value = args['chapter_id'] ?? 0;
    chapterNumber.value = args['chapter_number'] ?? 0;
    grade.value = args['grade'] ?? 9;

    loadGradeTests(subjectId.value, grade.value);

    super.onInit();
  }

  Future<void> loadGradeTests(int subjectId, int grade) async {
    try {
      isLoading.value = true;
      chapterTest.clear();
      testHasQuestions.clear();
      testResults.clear();

      final dbChapterTests = await _testRepository.getLocalTests(
        subjectId: subjectId,
        grade: grade,
      );

      late List<TestModel> data;

      data = dbChapterTests.map((e) => TestModel.fromMap(e)).toList();

      chapterTest.assignAll(data);

      await loadTestQuestionFlags(data);
      await loadTestResults(data);
    } catch (e) {
      AppExceptionHandler.handleResponse(e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadTestQuestionFlags(List<TestModel> tests) async {
    try {
      for (final test in tests) {
        final hasQn = await _testRepository.hasQns(test.id);
        testHasQuestions[test.id] = hasQn;
      }
    } catch (e) {
      AppExceptionHandler.handleResponse(e);
    }
  }

  List<TestModel> getTestsByGradeAndChapter(int? grade, int? chapterId) {
    if (grade == null || chapterId == null) return chapterTest;

    return chapterTest
        .where((e) => e.grade == grade && e.chapterId == chapterId)
        .toList();
  }

  // load saved test
  Future<void> loadTestResults(List<TestModel> tests) async {
    try {
      for (final test in tests) {
        final result = await _testRepository.loadSavedResults(test.id);
        if (result != null) {
          testResults[test.id] = result;
        }
      }
    } catch (e) {
      AppExceptionHandler.handleResponse(e);
    }
  }

  int getCurrentStep(int testId) {
    final result = testResults[testId];

    if (result != null) {
      return result.correctAnswers;
    }

    return 0;
  }

  int getMaxStep(int testId) {
    final result = testResults[testId];

    if (result != null) {
      return result.testQuestions.length;
    }

    return 20;
  }
}
