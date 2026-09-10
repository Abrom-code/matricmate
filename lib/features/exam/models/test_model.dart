class TestModel {
  int id, subjectId, questionCount;
  int? grade, chapterId;
  int time;
  String title, type;
  String? description;
  DateTime createdAt;
  bool isPremium;

  TestModel({
    required this.id,
    required this.subjectId,
    required this.questionCount,
    this.grade,
    this.chapterId,
    required this.createdAt,
    required this.type,
    required this.title,
    required this.time,
    this.description,
    this.isPremium = true,
  });

  factory TestModel.fromJson(Map<String, dynamic> json) {
    final rawPremium = json['is_premium'];
    final bool isPrem = rawPremium == null
        ? true
        : (rawPremium == true ||
            rawPremium == 1 ||
            rawPremium == 'true' ||
            rawPremium == '1');

    return TestModel(
      id: json['id'],
      subjectId: json['subject_id'],
      questionCount: json['question_count'],
      grade: json['grade'],
      chapterId: json['chapter_id'],
      createdAt: DateTime.parse(json['created_at']),
      type: json['type'],
      title: json['title'],
      time: json['time'] ?? -1,
      description: json['description']?.toString(),
      isPremium: isPrem,
    );
  }

  factory TestModel.fromMap(Map<String, dynamic> map) =>
      TestModel.fromJson(map);

  /// Returns true if this test was created within the last 2 days for NEW badge.
  bool get isNew {
    final cutoff = DateTime.now().subtract(const Duration(days: 2));
    return createdAt.isAfter(cutoff);
  }

  TestModel copyWith({
    int? id,
    int? subjectId,
    int? questionCount,
    int? grade,
    int? chapterId,
    int? time,
    String? title,
    String? type,
    String? description,
    DateTime? createdAt,
    bool? isPremium,
  }) {
    return TestModel(
      id: id ?? this.id,
      subjectId: subjectId ?? this.subjectId,
      questionCount: questionCount ?? this.questionCount,
      grade: grade ?? this.grade,
      chapterId: chapterId ?? this.chapterId,
      createdAt: createdAt ?? this.createdAt,
      type: type ?? this.type,
      title: title ?? this.title,
      time: time ?? this.time,
      description: description ?? this.description,
      isPremium: isPremium ?? this.isPremium,
    );
  }

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
      'description': description,
      'is_premium': isPremium ? 1 : 0,
    };
  }
}
