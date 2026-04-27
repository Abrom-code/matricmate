import 'package:get/get.dart';
import 'package:matricmate/data/repositories/exam/question_repository.dart';
import 'package:matricmate/features/exam/controllers/bookmark_controller.dart';
import 'package:matricmate/features/exam/models/passage_model.dart';
import 'package:matricmate/features/exam/models/question_block.dart';
import 'package:matricmate/features/exam/models/question_model.dart';
import 'package:matricmate/utils/exceptions/app_failure_model.dart';
import 'package:matricmate/utils/helpers/toast_helper.dart';
import 'package:matricmate/utils/network_manager/network_manager.dart';

class QuestionController extends GetxController {
  static QuestionController get instance => Get.find();

  final QuestionRepository _repo = QuestionRepository();

  // cache passage
  final Map<int, PassageModel> _passageCache = {};

  // States
  final RxBool isLoading = false.obs;
  final RxBool isPassageLoading = false.obs; // Synchronized with UI refactor
  final RxList<QuestionModel> testQuestions = <QuestionModel>[].obs;
  final RxList<QuestionBlock> blocks = <QuestionBlock>[].obs;

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

  @override
  void onInit() {
    testId = Get.arguments['test_id'] ?? 0;
    loadTestQuestions(testId);
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

      final isConnected = await NetworkManager.instance.hasRealInternet();
      if (!isConnected) {
        ToastHelper.warning("No Internet!", "Please check your connection.");
        return;
      }

      final response = await _repo.getQnByTestIdRemote(testId);
      final data = (response as List)
          .map((e) => QuestionModel.fromJson(e))
          .toList();

      testQuestions.assignAll(data);
      blocks.assignAll(await buildBlocks(testQuestions));

      for (final q in data) {
        _repo.addQn(q);
        if (q.passageId != null) {
          final local = await _repo.getLocalPassage(q.passageId!);
          if (local.id == -1 || local.content.isEmpty) {
            final remote = await _repo.getRemotePassage(q.passageId!);
            if (remote != null) await _repo.addPassage(remote);
          }
        }
      }
    } catch (e) {
      handleException(e);
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
        current!.questions.add(q);
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

  void handleException(dynamic e) {
    if (e is AppFailure) {
      ToastHelper.error(e.title, e.message);
    } else {
      ToastHelper.error("Unexpected Error", e.toString());
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
}
