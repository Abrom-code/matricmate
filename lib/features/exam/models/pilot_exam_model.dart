class PilotExamModel {
  final int id;
  final String title;
  final String description;
  final String edition;
  final bool isActive;
  final String? createdAt;

  PilotExamModel({
    required this.id,
    required this.title,
    this.description = '',
    this.edition = '2017 E.C.',
    this.isActive = true,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'edition': edition,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt,
    };
  }

  factory PilotExamModel.fromMap(Map<String, dynamic> map) {
    return PilotExamModel(
      id: (map['id'] as num?)?.toInt() ?? 0,
      title: map['title'] as String? ?? 'Pilot Exam',
      description: map['description'] as String? ?? '',
      edition: map['edition'] as String? ?? '2017 E.C.',
      isActive: map['is_active'] == 1 || map['is_active'] == true,
      createdAt: map['created_at'] as String?,
    );
  }

  PilotExamModel copyWith({
    int? id,
    String? title,
    String? description,
    String? edition,
    bool? isActive,
    String? createdAt,
  }) {
    return PilotExamModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      edition: edition ?? this.edition,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class PilotExamSubjectModel {
  final int id;
  final int pilotExamId;
  final int subjectId;
  final String subjectName;
  final String stream; // 'natural', 'social', 'common'
  final int testId;
  final int orderIndex;
  final int questionCount;
  final int timeMinutes;

  PilotExamSubjectModel({
    required this.id,
    required this.pilotExamId,
    required this.subjectId,
    required this.subjectName,
    required this.stream,
    required this.testId,
    this.orderIndex = 1,
    this.questionCount = 60,
    this.timeMinutes = 90,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'pilot_exam_id': pilotExamId,
      'subject_id': subjectId,
      'subject_name': subjectName,
      'stream': stream,
      'test_id': testId,
      'order_index': orderIndex,
      'question_count': questionCount,
      'time_minutes': timeMinutes,
    };
  }

  factory PilotExamSubjectModel.fromMap(Map<String, dynamic> map) {
    return PilotExamSubjectModel(
      id: (map['id'] as num?)?.toInt() ?? 0,
      pilotExamId: (map['pilot_exam_id'] as num?)?.toInt() ?? 0,
      subjectId: (map['subject_id'] as num?)?.toInt() ?? 0,
      subjectName: map['subject_name'] as String? ?? 'Subject',
      stream: map['stream'] as String? ?? 'natural',
      testId: (map['test_id'] as num?)?.toInt() ?? 0,
      orderIndex: (map['order_index'] as num?)?.toInt() ?? 1,
      questionCount: (map['question_count'] as num?)?.toInt() ?? 60,
      timeMinutes: (map['time_minutes'] as num?)?.toInt() ?? 90,
    );
  }

  bool get isCommon => stream.toLowerCase() == 'common' || stream.toLowerCase() == 'both';
  bool get isNatural => stream.toLowerCase() == 'natural';
  bool get isSocial => stream.toLowerCase() == 'social';

  String get typeLabel {
    if (isCommon) return 'Common Subject';
    if (isNatural) return 'Natural Subject';
    if (isSocial) return 'Social Subject';
    return 'Exam Subject';
  }
}
