import 'package:get/get.dart';
import 'package:matricmate/data/repositories/exam/test_repository.dart';
import 'package:matricmate/features/exam/models/result_model.dart';
import 'package:matricmate/features/exam/models/test_model.dart';
import 'package:matricmate/utils/exceptions/exeption_handler.dart';

class EntranceExamsController extends GetxController {
  static EntranceExamsController get instance => Get.find();
  final TestRepository _testRepository = TestRepository();
  final RxList<TestModel> entranceTests = <TestModel>[].obs;
  final RxMap<int, bool> testHasQuestions = <int, bool>{}.obs;
  final RxMap<int, ResultModel> testResults = <int, ResultModel>{}.obs;

  final RxString subjectName = ''.obs;
  final RxInt subjectId = 0.obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    final args = Get.arguments ?? {};

    subjectName.value = args['subject'] ?? '';
    subjectId.value = args['subject_id'] ?? 0;

    loadEntranceTests(subjectId.value);

    super.onInit();
  }

  Future<void> loadEntranceTests(int subjectId) async {
    try {
      isLoading.value = true;
      testHasQuestions.clear();
      testResults.clear();

      final dbEntranceTests = await _testRepository.getLocalEntranceTests(
        subjectId,
      );

      late List<TestModel> data;

      data = dbEntranceTests.map((e) => TestModel.fromMap(e)).toList();

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

    return 20;
  }
}
