import 'package:get/get.dart';
import 'package:matricmate/data/database/database_service.dart';
import 'package:matricmate/data/repositories/challenge/challenge_repository.dart';
import 'package:matricmate/features/challenges/models/challenge_question_model.dart';
import 'package:matricmate/utils/exceptions/exception_handler.dart';

class ChallengePracticeController extends GetxController {
  ChallengePracticeController({
    required this.challengeId,
    required this.title,
    this.setId,
  });

  final String challengeId;
  final String title;
  final String? setId;

  final _db = DatabaseService.instance;
  final _repo = ChallengeRepository();

  final isLoading = true.obs;
  final questions = <ChallengeQuestionModel>[].obs;
  final currentIndex = 0.obs;

  // Selected answers: { question_id: selected_choice_index_or_text }
  final userAnswers = <String, String>{}.obs;

  int get totalQuestions => questions.length;
  ChallengeQuestionModel get currentQuestion => questions[currentIndex.value];

  @override
  void onInit() {
    super.onInit();
    loadQuestions();
  }

  Future<void> loadQuestions() async {
    isLoading.value = true;
    try {
      final rows = await _db.getDownloadedChallengeQuestions(challengeId);
      if (rows.isNotEmpty) {
        questions.value = rows
            .map((r) => ChallengeQuestionModel.fromJson(r))
            .toList();
      } else {
        // Fallback to online repository if not downloaded
        questions.value = await _repo.fetchQuestionsForReview(challengeId);
      }
    } catch (e) {
      AppExceptionHandler.handleResponse(e);
    } finally {
      isLoading.value = false;
    }
  }

  void selectOption(String choice) {
    if (userAnswers.containsKey(currentQuestion.id)) return; // Lock after picking for instant feedback
    userAnswers[currentQuestion.id] = choice;
  }

  void nextQuestion() {
    if (currentIndex.value < totalQuestions - 1) {
      currentIndex.value++;
    }
  }

  void prevQuestion() {
    if (currentIndex.value > 0) {
      currentIndex.value--;
    }
  }

  void goToQuestion(int index) {
    if (index >= 0 && index < totalQuestions) {
      currentIndex.value = index;
    }
  }
}
