import 'dart:convert';

class QuestionModel {
  int id;

  int subjectId;
  int? grade;

  int? chapterId;
  int testId;

  int? passageId;

  int? questionOrder;

  String questionText;
  String? imageUrl;

  int correctOptionIndex;

  String explanationEn;
  String explanationAm;

  List<String> options;

  QuestionModel({
    required this.id,
    required this.subjectId,
    required this.grade,
    required this.testId,
    required this.correctOptionIndex,
    required this.questionText,
    required this.options,

    this.chapterId,
    this.passageId,
    this.questionOrder,
    this.imageUrl,
    this.explanationEn = 'No English Explanation!',
    this.explanationAm = 'No Amharic Explanation!',
  });

  factory QuestionModel.fromMap(Map<String, dynamic> map) {
    return QuestionModel(
      id: map['id'],
      subjectId: map['subject_id'],
      grade: map['grade'],

      testId: map['test_id'],

      correctOptionIndex: map['correct_option_index'],
      questionText: map['question_text'] ?? '',

      chapterId: map['chapter_id'],
      passageId: map['passage_id'],
      questionOrder: map['question_order'],

      imageUrl: map['image_url']?.toString(),

      explanationEn:
          map['explanation_en']?.toString() ?? 'No English Explanation!',
      explanationAm:
          map['explanation_am']?.toString() ?? 'No Amharic Explanation!',

      options: map['options'] == null
          ? []
          : map['options'] is String
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
      'test_id': testId,

      'chapter_id': chapterId,
      'passage_id': passageId,
      'question_order': questionOrder,

      'question_text': questionText,
      'image_url': imageUrl,

      'correct_option_index': correctOptionIndex,

      'explanation_en': explanationEn,
      'explanation_am': explanationAm,

      'options': jsonEncode(options),
    };
  }

  factory QuestionModel.empty() {
    return QuestionModel(
      id: 0,
      subjectId: 0,
      grade: null,
      testId: 0,
      correctOptionIndex: 0,
      questionText: '',
      options: [],
      chapterId: null,
      passageId: null,
      questionOrder: null,
      imageUrl: null,
      explanationEn: 'No English Explanation!',
      explanationAm: 'No Amharic Explanation!',
    );
  }
}
