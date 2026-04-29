class TestModel {
  int id, subjectId, questionCount;
  int? grade, chapterId, time, point;
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
    this.point,
    this.time,
  });

  factory TestModel.fromJson(Map<String, dynamic> json) {
    return TestModel(
      id: json['id'],
      subjectId: json['subject_id'],
      questionCount: json['question_count'],
      grade: json['grade'],
      chapterId: json['chapter_id'],
      createdAt: DateTime.parse(json['created_at']),
      type: json['type'],
      title: json['title'],
      point: json['point'] ?? json['question_count'],
      time: json['time'] ?? -1,
    );
  }

  factory TestModel.fromMap(Map<String, dynamic> map) =>
      TestModel.fromJson(map);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'subject_id': subjectId,
      'question_count': questionCount,
      'grade': grade,
      'chapter_id': chapterId,
      'created_at': createdAt.toIso8601String(),
      'type': type,
      'title': title,
      'time': time,
      'point': point,
    };
  }
}
