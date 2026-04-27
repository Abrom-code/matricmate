import 'package:get/get.dart';
import 'package:matricmate/data/repositories/exam/test_repository.dart';
import 'package:matricmate/features/exam/models/result_model.dart';
import 'package:matricmate/features/exam/models/test_model.dart';
import 'package:matricmate/utils/exceptions/app_failure_model.dart';
import 'package:matricmate/utils/helpers/toast_helper.dart';
import 'package:matricmate/utils/network_manager/network_manager.dart';

class TestController extends GetxController {
  static TestController get instance => Get.find();
  final TestRepository _testRepository = TestRepository();
  final RxList<TestModel> chapterTest = <TestModel>[].obs;
  final RxList<TestModel> allGradeTests = <TestModel>[].obs;
  final RxList<TestModel> singleGradeTests = <TestModel>[].obs;
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

    loadGradeTests(grade.value);
    loadAllChapterTests(subjectId.value);

    super.onInit();
  }

  Future<void> loadAllChapterTests(int subjectId) async {
    try {
      isLoading.value = true;
      chapterTest.clear();
      testHasQuestions.clear();
      testResults.clear();

      final dbChapterTests = await _testRepository.getLocalTestsById(subjectId);

      late List<TestModel> data;

      if (dbChapterTests.isNotEmpty) {
        data = dbChapterTests.map((e) => TestModel.fromMap(e)).toList();
      } else {
        final isConnectd = await NetworkManager.instance.hasRealInternet();
        if (!isConnectd) {
          ToastHelper.warning(
            "No Internet!",
            "Please turn on mobile data or connect to WIFI!",
          );
          return;
        }

        final response = await _testRepository.getRemoteTestsById(subjectId);

        data = (response as List).map((e) => TestModel.fromJson(e)).toList();

        for (final test in data) {
          await _testRepository.addTest(test);
        }
      }

      chapterTest.assignAll(data);

      await loadTestQuestionFlags(data);
      loadAllGradeTests();
      await loadTestResults(data);
    } catch (e) {
      if (e is AppFailure) {
        ToastHelper.error(e.title, e.message);
      } else {
        ToastHelper.error("Unexpected Error", e.toString());
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadTestQuestionFlags(List<TestModel> tests) async {
    try {
      await Future.wait(
        tests.map((test) async {
          final hasQn = await _testRepository.hasQns(test.id);
          testHasQuestions[test.id] = hasQn;
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

  // load saved test
  Future<void> loadTestResults(List<TestModel> tests) async {
    try {
      await Future.wait(
        tests.map((test) async {
          final result = await _testRepository.loadSavedResults(test.id);
          if (result != null) {
            testResults[test.id] = result;
          }
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
