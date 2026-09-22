class ReportReasonOption {
  final String key;
  final String title;

  const ReportReasonOption({
    required this.key,
    required this.title,
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
    ),
    ReportReasonOption(
      key: 'unclear',
      title: 'Confusing or Incomplete Question',
    ),
    ReportReasonOption(
      key: 'broken_image',
      title: 'Missing or Broken Diagram/Image',
    ),
    ReportReasonOption(
      key: 'bad_explanation',
      title: 'Inaccurate Explanation',
    ),
    ReportReasonOption(
      key: 'other',
      title: 'Other Issue',
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
