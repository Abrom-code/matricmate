import 'package:get/get.dart';
import 'package:matricmate/data/repositories/exam/test_repository.dart';
import 'package:matricmate/features/exam/models/result_model.dart';
import 'package:matricmate/features/exam/models/test_model.dart';
import 'package:matricmate/utils/exceptions/exeption_handler.dart';

class ExamsController extends GetxController {
  static ExamsController get instance => Get.find();

  final TestRepository _testRepository = TestRepository();

  // Separate lists for each tab
  final RxList<TestModel> entranceTests = <TestModel>[].obs;
  final RxList<TestModel> modelTests = <TestModel>[].obs;

  final RxMap<int, bool> testHasQuestions = <int, bool>{}.obs;
  final RxMap<int, ResultModel> testResults = <int, ResultModel>{}.obs;
  final RxMap<int, int> testQuestionCounts = <int, int>{}.obs;

  final RxBool isLoading = false.obs;

  late String subjectName;
  late int subjectId;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments ?? {};
    subjectName = args['subject'] ?? '';
    subjectId = args['subject_id'] ?? 0;
    loadAllExams(subjectId);
  }

  Future<void> loadAllExams(int subjectId) async {
    try {
      isLoading.value = true;
      testHasQuestions.clear();
      testResults.clear();
      testQuestionCounts.clear();
      entranceTests.clear();
      modelTests.clear();

      // Load both types in parallel
      final results = await Future.wait([
        _testRepository.getLocalTests(subjectId: subjectId, type: 'entrance'),
        _testRepository.getLocalTests(subjectId: subjectId, type: 'model'),
      ]);

      final entrance = results[0].map((e) => TestModel.fromMap(e)).toList()
        ..sort((a, b) => b.title.compareTo(a.title));
      final model = results[1].map((e) => TestModel.fromMap(e)).toList()
        ..sort((a, b) => b.title.compareTo(a.title));

      entranceTests.assignAll(entrance);
      modelTests.assignAll(model);

      final all = [...entrance, ...model];
      await Future.wait([
        loadTestQuestionFlags(all),
        loadActualQuestionCounts(all),
        loadTestResults(all),
      ]);
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

  Future<void> loadActualQuestionCounts(List<TestModel> tests) async {
    try {
      await Future.wait(
        tests.map((test) async {
          final count = await _testRepository.getActualQuestionCount(test.id);
          testQuestionCounts[test.id] = count;
        }),
      );
    } catch (e) {
      AppExceptionHandler.handleResponse(e);
    }
  }

  Future<void> loadTestResults(List<TestModel> tests) async {
    try {
      for (final test in tests) {
        final result = await _testRepository.loadSavedResults(test.id);
        if (result != null) {
          testResults[test.id] = result;
        } else {
          // Remove any stale entry — the result was deleted or never existed.
          testResults.remove(test.id);
        }
      }
    } catch (e) {
      AppExceptionHandler.handleResponse(e);
    }
  }

  int getCurrentStep(int testId) =>
      testResults[testId]?.selectedAnswers.length ?? 0;

  int getCorrectAnswers(int testId) =>
      testResults[testId]?.correctAnswers ?? 0;

  bool isInProgress(int testId) =>
      testResults.containsKey(testId) &&
      testResults[testId]!.isCompleted == false;

  int getMaxStep(int testId) {
    final result = testResults[testId];
    if (result != null) return result.testQuestions.length;
    final all = [...entranceTests, ...modelTests];
    return all.firstWhereOrNull((t) => t.id == testId)?.questionCount ?? 0;
  }
}
