import 'package:get/get.dart';
import 'package:matricmate/data/database/database_service.dart';
import 'package:matricmate/features/exam/controllers/test_controller.dart';
import 'package:matricmate/features/exam/models/question_model.dart';
import 'package:matricmate/features/exam/models/result_model.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';
import 'package:matricmate/utils/helpers/toast_helper.dart';
import 'package:matricmate/utils/network_manager/network_manager.dart';
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

  Future<void> loadTestQuestions(int testId) async {
    try {
      isLoading.value = true;

      // reset state
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
}
