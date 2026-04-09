import 'dart:convert';

class QuestionModel {
  int? questionOrder, chapterId, passageId;
  int id, subjectId, grade, correctOptionIndex;
  String questionText;
  String? imageUrl, explanationEn, explanationAm;
  List<String> options;

  QuestionModel({
    required this.id,
    required this.subjectId,
    required this.correctOptionIndex,
    required this.grade,
    this.chapterId,
    this.explanationAm,
    this.explanationEn,
    this.imageUrl,
    required this.options,
    this.passageId,
    this.questionOrder,
    required this.questionText,
  });

  factory QuestionModel.fromMap(Map<String, dynamic> map) {
    return QuestionModel(
      id: map['id'],
      subjectId: map['subject_id'],
      grade: map['grade'],
      correctOptionIndex: map['correct_option_index'],
      chapterId: map['chapter_id'],
      passageId: map['passage_id'],
      questionOrder: map['question_order'],
      questionText: map['question_text'],
      imageUrl: map['image_url'],
      explanationEn: map['explanation_en'],
      explanationAm: map['explanation_am'],
      // Logic to handle JSON string or List if already decoded by a driver
      options: map['options'] is String
          ? List<String>.from(jsonDecode(map['options']))
          : List<String>.from(map['options']),
    );
  }

  factory QuestionModel.fromJson(Map<String, dynamic> json) =>
      QuestionModel.fromMap(json);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'subject_id': subjectId,
      'grade': grade,
      'correct_option_index': correctOptionIndex,
      'chapter_id': chapterId,
      'passage_id': passageId,
      'question_order': questionOrder,
      'question_text': questionText,
      'image_url': imageUrl,
      'explanation_en': explanationEn,
      'explanation_am': explanationAm,
      // Convert the List back to a JSON string for the JSONB/TEXT column
      'options': jsonEncode(options),
    };
  }
}
