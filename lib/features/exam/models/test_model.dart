class TestModel {
  int id, subjectId, questionCount;
  int? grade, chapterId;
  String title, type;
  DateTime createdAt;

  TestModel({
    required this.id,
    required this.subjectId,
    required this.questionCount,
    this.grade,
    this.chapterId,
    required this.createdAt,
    required this.type,
    required this.title,
  });

  factory TestModel.fromJson(json) {
    return TestModel(
      id: json['id'],
      subjectId: json['subject_id'],
      questionCount: json['question_count'],
      createdAt: json['created_at'],
      type: json['type'],
      title: json['title'],
    );
  }
  factory TestModel.fromMap(Map<String, dynamic> map) =>
      TestModel.fromJson(map);

  Map<String, dynamic> toMap(Map<String, dynamic> map) {
    return {
      'id': id,
      'subject_id': subjectId,
      'question_count': questionCount,
      'created_at': createdAt,
      'type': type,
      'title': title,
    };
  }
}
