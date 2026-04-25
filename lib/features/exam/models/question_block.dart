import 'package:matricmate/features/exam/models/passage_model.dart';
import 'package:matricmate/features/exam/models/question_model.dart';

class QuestionBlock {
  final int? passageId;
  final PassageModel? passage;
  final List<QuestionModel> questions;

  QuestionBlock({this.passageId, this.passage, required this.questions});

  bool get isPassage => passageId != null;
}
