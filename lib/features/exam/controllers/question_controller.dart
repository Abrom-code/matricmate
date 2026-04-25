import 'package:get/get.dart';
import 'package:matricmate/data/database/database_service.dart';
import 'package:matricmate/features/exam/controllers/bookmark_controller.dart';
import 'package:matricmate/features/exam/models/passage_model.dart';
import 'package:matricmate/features/exam/models/question_block.dart';
import 'package:matricmate/features/exam/models/question_model.dart';
import 'package:matricmate/features/exam/models/result_model.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';
import 'package:matricmate/utils/helpers/toast_helper.dart';
import 'package:matricmate/utils/network_manager/network_manager.dart';
import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class QuestionController extends GetxController {
  static QuestionController get instance => Get.find();

  // cache passage
  final Map<int, PassageModel> _passageCache = {};
  final RxBool isPassageLoading = false.obs;

  final SupabaseClient supabase = Supabase.instance.client;
  final DatabaseService _databaseService = DatabaseService.instance;

  final RxList<QuestionModel> testQuestions = <QuestionModel>[].obs;
  final RxMap<int, int> selectedAnswers = <int, int>{}.obs;
  final RxMap<int, bool> isChecked = <int, bool>{}.obs;
  final RxInt currentIndex = 0.obs;
  final RxBool isLoading = false.obs;
  final RxBool isExplanationExpanaded = false.obs;
  final RxString languageSelected = "EN".obs;
  var isFullScreenPassage = false.obs;

  // question block
  final RxList<QuestionBlock> blocks = <QuestionBlock>[].obs;
  final RxInt currentBlockIndex = 0.obs;

  // passage controller
  var isPassageHidden = false.obs;
  var textScale = 1.0.obs;

  @override
  void onInit() {
    final testId = Get.arguments as int;
    loadTestQuestions(testId);

    super.onInit();
  }

  Future<void> loadTestQuestions(int testId) async {
    try {
      isLoading.value = true;

      // reset state
      currentBlockIndex.value = 0;
      testQuestions.clear();
      selectedAnswers.clear();
      isChecked.clear();
      currentIndex.value = 0;
      isExplanationExpanaded.value = false;

      final dbQuestions = await _databaseService.getQuestionsByTest(testId);

      if (dbQuestions.isNotEmpty) {
        testQuestions.assignAll(
          dbQuestions.map((e) => QuestionModel.fromMap(e)).toList(),
        );
        blocks.assignAll(await buildBlocks(testQuestions));
        return;
      }

      final isConnectd = await NetworkManager.instance.hasRealInternet();
      if (!isConnectd) {
        ToastHelper.warning(
          "No Internet!",
          "Please turn on mobile data or connect to WIFI!",
        );
        return;
      }

      final response = await supabase
          .from('questions')
          .select()
          .eq('test_id', testId)
          .order('question_order');

      final data = (response as List)
          .map((e) => QuestionModel.fromJson(e))
          .toList();

      testQuestions.assignAll(data);
      blocks.assignAll(await buildBlocks(testQuestions));

      final db = await _databaseService.database;

      for (final q in data) {
        await db.insert(
          'questions',
          q.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    } catch (e) {
      AppHelperFuntions.showAlert("Question Error", e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  void nextBlock() {
    if (currentBlockIndex.value < blocks.length - 1) {
      currentBlockIndex.value++;

      // jump to first question of block
      final firstQ = blocks[currentBlockIndex.value].questions.first;
      currentIndex.value = testQuestions.indexOf(firstQ);

      isExplanationExpanaded.value = false;
    }
  }

  void previousBlock() {
    if (currentBlockIndex.value > 0) {
      currentBlockIndex.value--;

      final firstQ = blocks[currentBlockIndex.value].questions.first;
      currentIndex.value = testQuestions.indexOf(firstQ);

      isExplanationExpanaded.value = false;
    }
  }

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

  void selectAnswer(int questionId, int optionIndex) {
    if (isChecked[questionId] == true) return;
    selectedAnswers[questionId] = optionIndex;
  }

  bool isAnswered(int questionId) {
    return selectedAnswers.containsKey(questionId);
  }

  int? getSelectedAnswer(int questionId) {
    return selectedAnswers[questionId];
  }

  void checkAnswer(int questionId) {
    if (selectedAnswers.containsKey(questionId)) {
      isChecked[questionId] = true;
    }
  }

  bool isAnswerChecked(int questionId) {
    return isChecked[questionId] ?? false;
  }

  int get correctAnswers {
    int score = 0;

    for (final q in testQuestions) {
      final selected = selectedAnswers[q.id];
      if (selected != null && selected == q.correctOptionIndex) {
        score++;
      }
    }

    return score;
  }

  Future<bool> saveResult(ResultModel result) async {
    try {
      final db = await _databaseService.database;
      await db.insert(
        'results',
        result.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      ToastHelper.success("Success", "Your result is saved!");
      return true;
    } catch (e) {
      ToastHelper.error("Faild!", e.toString());
      return false;
    }
  }

  bool isBookmarked(int questionId) {
    return BookmarkController.instance.bookmarkedIds.contains(questionId);
  }

  Future<List<QuestionBlock>> buildBlocks(List<QuestionModel> questions) async {
    final List<QuestionBlock> blocks = [];

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
        if (current != null) {
          blocks.add(current);
        }

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

    if (current != null) {
      blocks.add(current);
    }

    return blocks;
  }

  Future<PassageModel> getPassage(int? pId) async {
    try {
      if (pId == null) {
        return PassageModel(id: -1, content: "", title: "");
      }

      // CACHE HIT
      if (_passageCache.containsKey(pId)) {
        return _passageCache[pId]!;
      }

      isPassageLoading.value = true;

      final passage = await _databaseService.getPassage(pId);

      // SAVE TO CACHE
      _passageCache[pId] = passage;

      return passage;
    } catch (e) {
      ToastHelper.error("Error", e.toString());

      return PassageModel(
        id: -1,
        content: "Error loading passage",
        title: "Error",
      );
    } finally {
      isPassageLoading.value = false;
    }
  }

  void togglePassage() {
    isPassageHidden.value = !isPassageHidden.value;
  }

  /// Increase text size
  void increaseTextScale() {
    if (textScale.value < 1.4) {
      textScale.value += 0.1;
    }
  }

  /// Decrease text size
  void decreaseTextScale() {
    if (textScale.value > 0.8) {
      textScale.value -= 0.1;
    }
  }

  void togglePassageSize() {
    isFullScreenPassage.value = !isFullScreenPassage.value;
  }
}
