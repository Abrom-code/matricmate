import 'package:get/get.dart';
import 'package:matricmate/data/repositories/exam/question_repository.dart';
import 'package:matricmate/features/exam/models/passage_model.dart';
import 'package:matricmate/features/exam/models/question_model.dart';
import 'package:matricmate/features/exam/models/result_model.dart';

class ReviewController extends GetxController {
  static ReviewController get instance => Get.find();

  final QuestionRepository _repo = QuestionRepository();

  final RxMap<int, bool> isExpanded = <int, bool>{}.obs;
  final RxMap<int, bool> isPassageExpanded = <int, bool>{}.obs;
  final RxString languageSelected = 'EN'.obs;
  final RxMap<int, PassageModel> passages = <int, PassageModel>{}.obs;
  final RxString selectedFilter = 'All'.obs;

  late ResultModel result;
  late final List<QuestionModel> allQuestions;
  late final List<QuestionModel> correctQuestions;
  late final List<QuestionModel> wrongQuestions;
  late final List<QuestionModel> skippedQuestions;

  List<QuestionModel> get filteredQuestions {
    switch (selectedFilter.value) {
      case 'Correct':
        return correctQuestions;
      case 'Wrong':
        return wrongQuestions;
      case 'Skipped':
        return skippedQuestions;
      default:
        return allQuestions;
    }
  }

  @override
  void onInit() {
    super.onInit();
    final res = Get.arguments;
    if (res == null || res is! ResultModel) {
      Get.back();
      return;
    }
    result = res;

    allQuestions = result.testQuestions;
    correctQuestions = result.testQuestions
        .where((q) => result.selectedAnswers[q.id] == q.correctOptionIndex)
        .toList(growable: false);
    wrongQuestions = result.testQuestions
        .where((q) =>
            result.selectedAnswers[q.id] != null &&
            result.selectedAnswers[q.id] != q.correctOptionIndex)
        .toList(growable: false);
    skippedQuestions = result.testQuestions
        .where((q) => result.selectedAnswers[q.id] == null)
        .toList(growable: false);

    initExpansion(res.testQuestions);
    _loadPassages(res.testQuestions);
  }

  void initExpansion(List<QuestionModel> questions) {
    isExpanded.value = {for (var q in questions) q.id: false};
    isPassageExpanded.value = {for (var q in questions) q.id: false};
  }

  void toggle(int id) {
    isExpanded[id] = !(isExpanded[id] ?? false);
  }

  void togglePassage(int id) {
    isPassageExpanded[id] = !(isPassageExpanded[id] ?? false);
  }

  Future<void> _loadPassages(List<QuestionModel> questions) async {
    final passageIds = questions
        .where((q) => q.passageId != null)
        .map((q) => q.passageId!)
        .toSet();

    for (final pid in passageIds) {
      if (!passages.containsKey(pid)) {
        try {
          final p = await _repo.getLocalPassage(pid);
          passages[pid] = p;
        } catch (_) {}
      }
    }
  }
}
