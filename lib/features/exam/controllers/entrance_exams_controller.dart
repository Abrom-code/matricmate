import 'package:get/get.dart';
import 'package:matricmate/data/repositories/exam/test_repository.dart';
import 'package:matricmate/features/exam/models/result_model.dart';
import 'package:matricmate/features/exam/models/test_model.dart';
import 'package:matricmate/utils/exceptions/exeption_handler.dart';

class ExamsController extends GetxController {
  static ExamsController get instance => Get.find();
  final TestRepository _testRepository = TestRepository();
  final RxList<TestModel> entranceTests = <TestModel>[].obs;
  final RxMap<int, bool> testHasQuestions = <int, bool>{}.obs;
  final RxMap<int, ResultModel> testResults = <int, ResultModel>{}.obs;

  final RxBool isLoading = false.obs;
  late String subjectName;
  late int subjectId;
  late String type;

  @override
  void onInit() {
    final args = Get.arguments ?? {};

    subjectName = args['subject'] ?? '';
    subjectId = args['subject_id'] ?? 0;
    type = args['type'] ?? 'entrance';
    loadExams(subjectId, type);

    super.onInit();
  }

  Future<void> loadExams(int subjectId, String type) async {
    try {
      isLoading.value = true;
      testHasQuestions.clear();
      testResults.clear();

      final dbExams = await _testRepository.getLocalTests(
        subjectId: subjectId,
        type: type,
      );

      late List<TestModel> data;

      data = dbExams.map((e) => TestModel.fromMap(e)).toList();

      entranceTests.assignAll(data);

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

    final test = entranceTests.firstWhereOrNull((t) => t.id == testId);
    return test?.questionCount ?? 0;
  }
}
