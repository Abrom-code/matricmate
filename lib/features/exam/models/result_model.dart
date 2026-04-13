import 'package:matricmate/features/exam/models/question_model.dart';

class ResultModel {
  final List<QuestionModel> testQuestions;
  final Map<int, int> selectedAnswers;
  final int correctAnswers;
  ResultModel({
    required this.selectedAnswers,
    required this.testQuestions,
    required this.correctAnswers,
  });
}
