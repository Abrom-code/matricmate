class ChapterModel {
  int id, subjectId, grade, chapterNumber;
  String title;
  ChapterModel({
    required this.id,
    required this.subjectId,
    required this.grade,
    required this.chapterNumber,
    required this.title,
  });

  // Convert Json to ChapterModel object
  factory ChapterModel.fromJson(Map<String, dynamic> json) {
    return ChapterModel(
      id: (json['id'] as num).toInt(),
      title: json['title']?.toString() ?? '',
      subjectId: (json['subject_id'] as num).toInt(),
      grade: (json['grade'] as num).toInt(),
      chapterNumber: (json['chapter_number'] as num).toInt(),
    );
  }

  // Convert DB Map to ChapterModel object
  factory ChapterModel.fromMap(Map<String, dynamic> json) =>
      ChapterModel.fromJson(json);

  // Convert ChapterModel object to Map for DB insertion
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'subject_id': subjectId,
      'chapter_number': chapterNumber,
      'grade': grade,
      'title': title,
    };
  }
}
