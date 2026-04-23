class BookmarkModel {
  final int questionId;
  final int savedAt;
  final String userId;
  BookmarkModel({
    required this.questionId,
    required this.savedAt,
    required this.userId,
  });

  Map<String, dynamic> toMap() {
    return {'question_id': questionId, 'saved_at': savedAt, 'user_id': userId};
  }

  factory BookmarkModel.fromMap(Map<String, dynamic> map) {
    return BookmarkModel(
      questionId: map['question_id'],
      savedAt: map['saved_at'],
      userId: map['user_id'],
    );
  }
}
