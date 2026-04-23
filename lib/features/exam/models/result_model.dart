import 'dart:convert';
import 'package:matricmate/features/exam/models/question_model.dart';

class ResultModel {
  final int testId;
  final List<QuestionModel> testQuestions;
  final Map<int, int> selectedAnswers;
  final int correctAnswers;
  final String userId;

  ResultModel({
    required this.testQuestions,
    required this.selectedAnswers,
    required this.correctAnswers,
    required this.testId,
    required this.userId,
  });

  Map<String, dynamic> toMap() {
    return {
      'testQuestions': jsonEncode(testQuestions.map((q) => q.toMap()).toList()),

      'selectedAnswers': jsonEncode(
        selectedAnswers.map((key, value) => MapEntry(key.toString(), value)),
      ),

      'correctAnswers': correctAnswers,
      'test_id': testId,
      'user_id': userId,
    };
  }

  factory ResultModel.fromMap(Map<String, dynamic> map) {
    return ResultModel(
      testQuestions: map['testQuestions'] == null
          ? []
          : List<QuestionModel>.from(
              jsonDecode(
                map['testQuestions'],
              ).map((q) => QuestionModel.fromMap(q)),
            ),

      selectedAnswers: map['selectedAnswers'] == null
          ? {}
          : Map<String, dynamic>.from(
              jsonDecode(map['selectedAnswers']),
            ).map((key, value) => MapEntry(int.parse(key), value)),

      correctAnswers: map['correctAnswers'] ?? 0,
      testId: map['test_id'],
      userId: map['user_id'],
    );
  }
}
