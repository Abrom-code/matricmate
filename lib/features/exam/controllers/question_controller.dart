import 'dart:async';

import 'package:get/get.dart';
import 'package:matricmate/data/repositories/exam/question_repository.dart';
import 'package:matricmate/features/exam/controllers/bookmark_controller.dart';
import 'package:matricmate/features/exam/models/passage_model.dart';
import 'package:matricmate/features/exam/models/question_block.dart';
import 'package:matricmate/features/exam/models/question_model.dart';
import 'package:matricmate/features/exam/models/result_model.dart';
import 'package:matricmate/features/personalization/controller/user_controller.dart';
import 'package:matricmate/routes/app_routes.dart';
import 'package:matricmate/utils/exceptions/app_failure_model.dart';
import 'package:matricmate/utils/exceptions/exeption_handler.dart';
import 'package:matricmate/utils/helpers/toast_helper.dart';

class QuestionController extends GetxController {
  static QuestionController get instance => Get.find();

  final QuestionRepository _repo = QuestionRepository();

  // cache passage
  final Map<int, PassageModel> _passageCache = {};

  // States
  final RxBool isLoading = false.obs;
  final RxBool isPassageLoading = false.obs;
  final RxList<QuestionModel> testQuestions = <QuestionModel>[].obs;
  final RxList<QuestionBlock> blocks = <QuestionBlock>[].obs;

  // timer
  final RxInt remainingSeconds = 0.obs;
  Timer? _timer;

  final RxMap<int, int> selectedAnswers = <int, int>{}.obs;
  final RxMap<int, bool> isChecked = <int, bool>{}.obs;
  final RxInt currentIndex = 0.obs;
  final RxInt currentBlockIndex = 0.obs;
  final RxBool isExplanationExpanaded = false.obs;
  final RxString languageSelected = "EN".obs;
  var isFullScreenPassage = false.obs;
  var isPassageHidden = false.obs;
  var textScale = 1.0.obs;
  late int testId;
  late bool isTimed;
  late int time;

  @override
  void onInit() {
    testId = Get.arguments['test_id'];
    isTimed = Get.arguments['is_timed'];
    time = Get.arguments['time'];
    loadTestQuestions(testId);
    if (isTimed) startTimer(time);
    super.onInit();
  }

  Future<void> loadTestQuestions(int testId) async {
    try {
      isLoading.value = true;

      currentBlockIndex.value = 0;
      testQuestions.clear();
      blocks.clear();
      selectedAnswers.clear();
      isChecked.clear();
      currentIndex.value = 0;

      final dbQuestions = await _repo.getQnByTestIdLocal(testId);

      if (dbQuestions.isNotEmpty) {
        testQuestions.assignAll(
          dbQuestions.map((e) => QuestionModel.fromMap(e)).toList(),
        );
        blocks.assignAll(await buildBlocks(testQuestions));
        return;
      }
    } catch (e) {
      AppExceptionHandler.handleResponse(e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<List<QuestionBlock>> buildBlocks(List<QuestionModel> questions) async {
    try {
      isPassageLoading.value = true;
      final List<QuestionBlock> newBlocks = [];
      QuestionBlock? current;
      int? lastPassageId;
      bool lastWasPassage = false;

      for (final q in questions) {
        final isPassage = q.passageId != null;
        final isNewBlock =
            current == null ||
            q.passageId != lastPassageId ||
            isPassage != lastWasPassage;

        if (isNewBlock) {
          if (current != null) newBlocks.add(current);

          PassageModel? passage;
          if (q.passageId != null) {
            passage = await getPassage(q.passageId);
          }

          current = QuestionBlock(
            passageId: q.passageId,
            passage: passage,
            questions: [],
          );

          lastPassageId = q.passageId;
          lastWasPassage = isPassage;
        }
        current.questions.add(q);
      }

      if (current != null) newBlocks.add(current);
      return newBlocks;
    } finally {
      isPassageLoading.value = false;
    }
  }

  Future<PassageModel> getPassage(int? pId) async {
    if (pId == null) return PassageModel(id: -1, content: "", title: "");
    if (_passageCache.containsKey(pId)) return _passageCache[pId]!;
    final passage = await _repo.getLocalPassage(pId);
    _passageCache[pId] = passage;
    return passage;
  }

  void checkAnswer(int questionId) {
    isChecked[questionId] = true;
  }

  int get correctAnswers {
    int score = 0;
    for (final q in testQuestions) {
      final selected = selectedAnswers[q.id];
      // Check if the selected index matches the model's correct index
      if (selected != null && selected == q.correctOptionIndex) {
        score++;
      }
    }
    return score;
  }

  Future<void> saveResult(ResultModel result) async {
    try {
      await _repo.saveResult(result);
    } catch (e) {
      if (e is AppFailure) {
        ToastHelper.error(
          "Sync Failed",
          "Result saved locally only. ${e.message}",
        );
      } else {
        ToastHelper.error("Unexpected Error", "Could not sync result.");
      }
    }
  }

  // Navigation Logic
  void nextQuestion() {
    if (currentIndex.value < testQuestions.length - 1) {
      currentIndex.value++;
      _syncBlockWithIndex();
      isExplanationExpanaded.value = false;
    }
  }

  void previousQuestion() {
    if (currentIndex.value > 0) {
      currentIndex.value--;
      _syncBlockWithIndex();
      isExplanationExpanaded.value = false;
    }
  }

  void _syncBlockWithIndex() {
    final currentQ = testQuestions[currentIndex.value];
    for (int i = 0; i < blocks.length; i++) {
      if (blocks[i].questions.contains(currentQ)) {
        currentBlockIndex.value = i;
        break;
      }
    }
  }

  // Answer Selection logic
  void selectAnswer(int questionId, int optionIndex) {
    if (isChecked[questionId] == true) return;
    selectedAnswers[questionId] = optionIndex;
  }

  bool isBookmarked(int questionId) =>
      BookmarkController.instance.bookmarkedIds.contains(questionId);

  // Formatting helpers
  void increaseTextScale() =>
      textScale.value < 1.4 ? textScale.value += 0.1 : null;
  void decreaseTextScale() =>
      textScale.value > 0.8 ? textScale.value -= 0.1 : null;
  void togglePassage() => isPassageHidden.value = !isPassageHidden.value;
  void togglePassageSize() =>
      isFullScreenPassage.value = !isFullScreenPassage.value;

  bool isAnswerChecked(int questionId) {
    return isChecked[questionId] ?? false;
  }

  int? getSelectedAnswer(int questionId) {
    return selectedAnswers[questionId];
  }

  /// timer section
  void startTimer(int minutes) {
    _timer?.cancel();

    remainingSeconds.value = minutes * 60;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (remainingSeconds.value == 2)
        ToastHelper.warning("Time's up!", "Submitting ...");

      if (remainingSeconds.value <= 1) {
        remainingSeconds.value = 0;
        timer.cancel();

        _onTimeUp();
        return;
      }

      remainingSeconds.value--;
    });
  }

  void _onTimeUp() {
    final result = ResultModel(
      userId: UserController.instance.user.value.id,
      testId: testId,
      selectedAnswers: selectedAnswers,
      testQuestions: testQuestions.toList(),
      correctAnswers: correctAnswers,
    );

    saveResult(result);

    Get.offNamed(Routes.result, arguments: {'result': result});
  }

  String get formattedTime {
    final hours = remainingSeconds.value ~/ 3600;
    final minutes = (remainingSeconds.value % 3600) ~/ 60;
    final seconds = remainingSeconds.value % 60;

    return '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }
}
