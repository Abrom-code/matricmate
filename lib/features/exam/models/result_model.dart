import 'dart:convert';
import 'package:matricmate/features/exam/models/question_model.dart';

class ResultModel {
  final int testId;
  final List<QuestionModel> testQuestions;
  final Map<int, int> selectedAnswers;
  final int correctAnswers;
  final String userId;

  /// `true` = final submitted result; `false` = in-progress draft.
  final bool isCompleted;

  /// Question IDs whose answers were revealed (practice mode checked state).
  /// Empty for exam-mode sessions and completed results.
  final Set<int> checkedQuestions;

  ResultModel({
    required this.testQuestions,
    required this.selectedAnswers,
    required this.correctAnswers,
    required this.testId,
    required this.userId,
    this.isCompleted = true,
    Set<int>? checkedQuestions,
  }) : checkedQuestions = checkedQuestions ?? {};

  Map<String, dynamic> toMap() {
    return {
      'testQuestions': jsonEncode(testQuestions.map((q) => q.toMap()).toList()),
      'selectedAnswers': jsonEncode(
        selectedAnswers.map((key, value) => MapEntry(key.toString(), value)),
      ),
      'correctAnswers': correctAnswers,
      'test_id': testId,
      'user_id': userId,
      'isCompleted': isCompleted ? 1 : 0,
      'checkedQuestions': jsonEncode(checkedQuestions.toList()),
    };
  }

  factory ResultModel.fromMap(Map<String, dynamic> map) {
    Set<int> checked = {};
    if (map['checkedQuestions'] != null) {
      try {
        checked = Set<int>.from(
          (jsonDecode(map['checkedQuestions'] as String) as List)
              .map((e) => (e as num).toInt()),
        );
      } catch (_) {}
    }

    return ResultModel(
      testQuestions: map['testQuestions'] == null
          ? []
          : List<QuestionModel>.from(
              jsonDecode(map['testQuestions'])
                  .map((q) => QuestionModel.fromMap(q)),
            ),
      selectedAnswers: map['selectedAnswers'] == null
          ? {}
          : Map<String, dynamic>.from(
              jsonDecode(map['selectedAnswers']),
            ).map((key, value) =>
                MapEntry(int.parse(key), (value as num).toInt())),
      correctAnswers: map['correctAnswers'] ?? 0,
      testId: map['test_id'],
      userId: map['user_id'],
      isCompleted: (map['isCompleted'] as int? ?? 1) == 1,
      checkedQuestions: checked,
    );
  }
}
