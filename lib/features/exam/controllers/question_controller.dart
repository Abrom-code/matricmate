import 'package:get/get.dart';
import 'package:matricmate/data/database/database_service.dart';
import 'package:matricmate/features/exam/models/question_model.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';
import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class QuestionController extends GetxController {
  static QuestionController get instance => Get.find();

  final SupabaseClient supabase = Supabase.instance.client;
  final DatabaseService _databaseService = DatabaseService.instance;

  final RxList<QuestionModel> testQuestions = <QuestionModel>[].obs;
  final RxMap<int, int> selectedAnswers = <int, int>{}.obs;
  final RxMap<int, bool> isChecked = <int, bool>{}.obs;
  final RxInt currentIndex = 0.obs;
  final RxBool isLoading = false.obs;
  final RxBool isExplanationExpanaded = false.obs;
  final RxString languageSelected = "EN".obs;

  @override
  void onInit() {
    final testId = Get.arguments as int?;
    if (testId != null) {
      loadTestQuestions(testId);
    }
    super.onInit();
  }

  Future<void> loadTestQuestions(int testId) async {
    try {
      isLoading.value = true;

      final dbQuestions = await _databaseService.getQuestionsByTest(testId);

      if (dbQuestions.isNotEmpty) {
        testQuestions.assignAll(
          dbQuestions.map((e) => QuestionModel.fromMap(e)).toList(),
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

  void nextQuestion() {
    if (currentIndex.value < testQuestions.length - 1) {
      currentIndex.value++;
      isExplanationExpanaded.value = false;
    }
  }

  void previousQuestion() {
    if (currentIndex.value > 0) {
      currentIndex.value--;
      isExplanationExpanaded.value = false;
    }
  }

  bool isAnswered(int questionId) {
    return selectedAnswers.containsKey(questionId);
  }

  void selectAnswer(int questionId, int optionIndex) {
    if (isChecked[questionId] == true) return;

    selectedAnswers[questionId] = optionIndex;
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
}
