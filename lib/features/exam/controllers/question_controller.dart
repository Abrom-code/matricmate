import 'dart:async';

import 'package:get/get.dart';
import 'package:matricmate/data/repositories/exam/question_repository.dart';
import 'package:matricmate/features/exam/controllers/bookmark_controller.dart';
import 'package:matricmate/features/exam/models/passage_model.dart';
import 'package:matricmate/features/exam/models/question_block.dart';
import 'package:matricmate/features/exam/models/question_model.dart';
import 'package:matricmate/features/exam/models/result_model.dart';
import 'package:matricmate/features/personalization/controllers/user_controller.dart';
import 'package:matricmate/routes/app_routes.dart';
import 'package:matricmate/utils/exceptions/exception_handler.dart';
import 'package:matricmate/utils/formatter/formatter.dart';
import 'package:matricmate/utils/helpers/snackbar_helper.dart';
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
  final RxList<QuestionBlockModel> blocks = <QuestionBlockModel>[].obs;

  // timer
  final RxInt remainingSeconds = 0.obs;
  Timer? _timer;

  final RxMap<int, int> selectedAnswers = <int, int>{}.obs;
  final RxMap<int, bool> isChecked = <int, bool>{}.obs;
  final RxSet<int> skippedQuestions = <int>{}.obs;
  final RxInt currentIndex = 0.obs;
  final RxInt currentBlockIndex = 0.obs;
  final RxBool isExplanationExpanded = false.obs;
  final RxBool isFullScreenPassage = false.obs;
  final RxBool isPassageHidden = false.obs;
  final RxDouble textScale = 1.0.obs;
  final RxString languageSelected = 'EN'.obs;
  late int testId;
  late bool isTimed;
  late bool isExamMode;
  late int time;
  late int ctrlId;

  /// Flag indicating submission is complete to prevent draft overwrites.
  bool _isSubmitted = false;

  /// Pauses the timer without cancelling it (used when the exit dialog is open).
  bool _timerPaused = false;

  @override
  void onInit() {
    testId = Get.arguments['test_id'];
    isTimed = Get.arguments['is_timed'];
    isExamMode = Get.arguments['is_exam_mode'] ?? false;
    time = Get.arguments['time'];
    ctrlId = Get.arguments['id'];

    // Restore in-progress draft if the user is resuming
    final draft = Get.arguments['draft'] as ResultModel?;

    loadTestQuestions(testId, draft: draft);

    if (isTimed) {
      // If resuming a timed draft, start from where the timer was saved.
      final savedSeconds = (draft != null && draft.remainingSeconds > 0)
          ? draft.remainingSeconds
          : null;
      startTimerFromSeconds(savedSeconds ?? time * 60);
    }

    super.onInit();
  }

  Future<void> loadTestQuestions(int testId, {ResultModel? draft}) async {
    try {
      isLoading.value = true;

      currentBlockIndex.value = 0;
      testQuestions.clear();
      blocks.clear();
      selectedAnswers.clear();
      isChecked.clear();
      skippedQuestions.clear();
      currentIndex.value = 0;

      final dbQuestions = await _repo.getQnByTestIdLocal(testId);

      if (dbQuestions.isNotEmpty) {
        testQuestions.assignAll(
          dbQuestions.map((e) => QuestionModel.fromMap(e)).toList(),
        );
        blocks.assignAll(await buildBlocks(testQuestions));

        // Restore draft answers and jump to the last answered question.
        if (draft != null &&
            draft.selectedAnswers.isNotEmpty &&
            !draft.isCompleted) {
          selectedAnswers.assignAll(draft.selectedAnswers);

          // Restore which questions had their answer revealed.
          if (draft.checkedQuestions.isNotEmpty) {
            for (final qId in draft.checkedQuestions) {
              isChecked[qId] = true;
            }
          }
          // In practice mode every selected answer was checked — fill any
          if (!isExamMode) {
            for (final qId in draft.selectedAnswers.keys) {
              isChecked[qId] = true;
            }
          }

          // Jump to the first unanswered question, or last if all done
          final firstUnansweredIndex = testQuestions.indexWhere(
            (q) => !draft.selectedAnswers.containsKey(q.id),
          );
          currentIndex.value = firstUnansweredIndex == -1
              ? testQuestions.length - 1
              : firstUnansweredIndex;
          _syncBlockWithIndex();
        }
        return;
      }
    } catch (e) {
      AppExceptionHandler.handleResponse(e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<List<QuestionBlockModel>> buildBlocks(
    List<QuestionModel> questions,
  ) async {
    try {
      isPassageLoading.value = true;
      final List<QuestionBlockModel> newBlocks = [];
      QuestionBlockModel? current;
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

          current = QuestionBlockModel(
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
    if (pId == null) return PassageModel(id: -1, content: '', title: '');
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
      ToastHelper.error('Could not sync result.');
    }
  }

  /// Marks submission finished before navigating to results.
  void markSubmitted() {
    _isSubmitted = true;
  }

  // Navigation Logic
  void nextQuestion() {
    if (currentIndex.value < testQuestions.length - 1) {
      currentIndex.value++;
      _syncBlockWithIndex();
      isExplanationExpanded.value = false;
    }
  }

  void previousQuestion() {
    if (currentIndex.value > 0) {
      currentIndex.value--;
      _syncBlockWithIndex();
      isExplanationExpanded.value = false;
    }
  }

  void skipQuestion() {
    if (currentIndex.value < testQuestions.length - 1) {
      final q = testQuestions[currentIndex.value];
      skippedQuestions.add(q.id);
      selectedAnswers.remove(q.id); // clear any half-picked answer
      currentIndex.value++;
      _syncBlockWithIndex();
      isExplanationExpanded.value = false;
    }
  }

  bool isSkipped(int questionId) => skippedQuestions.contains(questionId);

  void jumpToQuestion(int index) {
    if (index < 0 || index >= testQuestions.length) return;
    currentIndex.value = index;
    _syncBlockWithIndex();
    isExplanationExpanded.value = false;
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
    // Pre-mark checked state in practice mode for draft consistency
    if (!isExamMode) {
      isChecked[questionId] = true;
    }
    _saveDraft();
  }

  /// Saves in-progress state as draft if not already submitted.
  void _saveDraft() {
    if (_isSubmitted) return; // already submitted — never overwrite
    final draft = ResultModel(
      userId: UserController.instance.user.value.id,
      testId: testId,
      selectedAnswers: Map.from(selectedAnswers),
      testQuestions: testQuestions.toList(),
      correctAnswers: correctAnswers,
      isCompleted: false,
      checkedQuestions: Set<int>.from(
        isChecked.entries.where((e) => e.value).map((e) => e.key),
      ),
      remainingSeconds: isTimed ? remainingSeconds.value : 0,
    );
    _repo
        .saveResult(draft)
        .then((_) {
          // Draft saved successfully.
        })
        .catchError((e) {
          ToastHelper.error('Draft save failed: $e');
        });
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
  void startTimer(int minutes) => startTimerFromSeconds(minutes * 60);

  void startTimerFromSeconds(int seconds) {
    _timer?.cancel();
    _timerPaused = false;

    remainingSeconds.value = seconds;
    int ticksSinceLastSave = 0;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      // Don't tick while the exit dialog is open
      if (_timerPaused) return;

      if (remainingSeconds.value == 2) {
        SnackbarHelper.warning("Time's up!", 'Submitting ...');
      }

      if (remainingSeconds.value <= 1) {
        remainingSeconds.value = 0;
        timer.cancel();
        _onTimeUp();
        return;
      }

      remainingSeconds.value--;
      ticksSinceLastSave++;

      // Save draft every 30 seconds so remaining time stays current
      if (ticksSinceLastSave >= 30 &&
          testQuestions.isNotEmpty &&
          selectedAnswers.isNotEmpty) {
        ticksSinceLastSave = 0;
        _saveDraft();
      }
    });
  }

  /// True while exit confirmation dialog is visible.
  bool _exitDialogOpen = false;

  /// Pauses the timer (dialog open). Does not cancel it.
  void pauseTimer() {
    _timerPaused = true;
    _exitDialogOpen = true;
  }

  /// Resumes the timer (dialog dismissed without exiting).
  void resumeTimer() {
    _timerPaused = false;
    _exitDialogOpen = false;
  }

  bool get exitDialogOpen => _exitDialogOpen;

  void _onTimeUp() {
    _isSubmitted = true;
    final result = ResultModel(
      userId: UserController.instance.user.value.id,
      testId: testId,
      selectedAnswers: selectedAnswers,
      testQuestions: testQuestions.toList(),
      correctAnswers: correctAnswers,
      isCompleted: true,
    );

    saveResult(result);

    Get.offNamed(Routes.result, arguments: {'result': result});
  }

  String formattedTime(int second) => AppFormatter.formattedTime(second);

  @override
  void onClose() {
    _timer?.cancel();
    // Save draft on exit if active and not yet submitted
    if (testQuestions.isNotEmpty &&
        !_isSubmitted &&
        selectedAnswers.isNotEmpty) {
      _saveDraft();
    }
    super.onClose();
  }
}
