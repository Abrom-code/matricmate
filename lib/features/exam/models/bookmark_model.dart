class BookmarkModel {
  final int questionId;
  final int savedAt;
  BookmarkModel({required this.questionId, required this.savedAt});

  Map<String, dynamic> toMap() {
    return {'question_id': questionId, 'saved_at': savedAt};
  }

  factory BookmarkModel.fromMap(Map<String, dynamic> map) {
    return BookmarkModel(
      questionId: map['question_id'],
      savedAt: map['saved_at'],
    );
  }
}
