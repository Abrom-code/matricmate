class ReportReasonOption {
  final String key;
  final String title;
  final String description;

  const ReportReasonOption({
    required this.key,
    required this.title,
    required this.description,
  });
}

class QuestionReportModel {
  final String? id;
  final String userId;
  final int? questionId;
  final String? challengeQuestionId;
  final int? testId;
  final String reason;
  final String? comment;
  final String status;
  final DateTime? createdAt;

  QuestionReportModel({
    this.id,
    required this.userId,
    this.questionId,
    this.challengeQuestionId,
    this.testId,
    required this.reason,
    this.comment,
    this.status = 'pending',
    this.createdAt,
  });

  static const List<ReportReasonOption> reasons = [
    ReportReasonOption(
      key: 'wrong_answer',
      title: 'Wrong Correct Answer',
      description: 'The indicated answer is not correct.',
    ),
    ReportReasonOption(
      key: 'typo',
      title: 'Typo or Spelling Mistake',
      description: 'There is a spelling or grammatical error in text/choices.',
    ),
    ReportReasonOption(
      key: 'unclear',
      title: 'Confusing or Incomplete Question',
      description: 'The question text is ambiguous, misleading, or cut off.',
    ),
    ReportReasonOption(
      key: 'broken_image',
      title: 'Missing or Broken Diagram/Image',
      description: 'The image or graph failed to load or is not visible.',
    ),
    ReportReasonOption(
      key: 'bad_explanation',
      title: 'Inaccurate Explanation',
      description: 'The solution explanation contains mistakes or misleading steps.',
    ),
    ReportReasonOption(
      key: 'other',
      title: 'Other Issue',
      description: 'Any other problem not covered above.',
    ),
  ];

  static String reasonLabel(String key) {
    final match = reasons.where((r) => r.key == key);
    return match.isNotEmpty ? match.first.title : key;
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      if (questionId != null) 'question_id': questionId,
      if (challengeQuestionId != null) 'challenge_question_id': challengeQuestionId,
      if (testId != null) 'test_id': testId,
      'reason': reason,
      if (comment != null && comment!.trim().isNotEmpty) 'comment': comment!.trim(),
      'status': status,
    };
  }

  factory QuestionReportModel.fromJson(Map<String, dynamic> json) {
    return QuestionReportModel(
      id: json['id']?.toString(),
      userId: json['user_id']?.toString() ?? '',
      questionId: (json['question_id'] as num?)?.toInt(),
      challengeQuestionId: json['challenge_question_id']?.toString(),
      testId: (json['test_id'] as num?)?.toInt(),
      reason: json['reason']?.toString() ?? 'other',
      comment: json['comment']?.toString(),
      status: json['status']?.toString() ?? 'pending',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }
}
