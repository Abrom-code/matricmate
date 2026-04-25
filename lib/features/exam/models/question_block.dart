import 'package:matricmate/features/exam/models/question_model.dart';

class QuestionBlock {
  final int? passageId;
  final String? passageText;
  final List<QuestionModel> questions;

  QuestionBlock({this.passageId, this.passageText, required this.questions});

  bool get isPassage => passageId != null;
}
