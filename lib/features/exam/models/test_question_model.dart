class TestQuestionModel {
  int? testId, position, questionId;
  TestQuestionModel({this.testId, this.position, this.questionId});

  factory TestQuestionModel.fromJson(Map<String, dynamic> json) {
    return TestQuestionModel(
      testId: json['test_id'],
      position: json['position'],
      questionId: json['question_id'],
    );
  }
  factory TestQuestionModel.fromMap(Map<String, dynamic> map) =>
      TestQuestionModel.fromJson(map);
  Map<String, dynamic> toMap() {
    return {'test_id': testId, 'position': position, 'question_id': questionId};
  }
}
