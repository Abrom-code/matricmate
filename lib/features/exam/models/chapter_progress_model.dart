class ChapterProgressModel {
  final int chapterId;
  final int grade;
  final int totalTests;
  final int completedTests;
  final int inProgressTests;
  final double? avgScore;

  ChapterProgressModel({
    required this.chapterId,
    required this.grade,
    required this.totalTests,
    required this.completedTests,
    this.inProgressTests = 0,
    this.avgScore,
  });

  factory ChapterProgressModel.fromMap(Map<String, dynamic> map) {
    return ChapterProgressModel(
      chapterId: map['chapter_id'] as int? ?? (map['grade'] as int? ?? 0),
      grade: map['grade'] as int? ?? 9,
      totalTests: map['total_tests'] as int? ?? 0,
      completedTests: map['completed_tests'] as int? ?? 0,
      inProgressTests: map['in_progress_tests'] as int? ?? 0,
      avgScore: map['avg_score'] != null
          ? (map['avg_score'] as num).toDouble()
          : null,
    );
  }

  bool get hasTests => totalTests > 0;
  bool get isCompleted => totalTests > 0 && completedTests >= totalTests;
  bool get isInProgress =>
      inProgressTests > 0 || (completedTests > 0 && completedTests < totalTests);
  double get progressPercentage =>
      totalTests > 0 ? (completedTests / totalTests).clamp(0.0, 1.0) : 0.0;
}

class GradeProgressSummary {
  final int totalTests;
  final int completedTests;
  final int inProgressTests;
  final int totalChapters;
  final int completedChapters;

  GradeProgressSummary({
    required this.totalTests,
    required this.completedTests,
    required this.inProgressTests,
    required this.totalChapters,
    required this.completedChapters,
  });

  double get progressPercentage =>
      totalTests > 0 ? (completedTests / totalTests).clamp(0.0, 1.0) : 0.0;

  bool get hasTests => totalTests > 0;
  bool get isCompleted => totalTests > 0 && completedTests >= totalTests;
  bool get isInProgress =>
      inProgressTests > 0 || (completedTests > 0 && completedTests < totalTests);
}
