import 'package:get/get.dart';
import 'package:matricmate/data/database/database_service.dart';
import 'package:matricmate/features/exam/controllers/subjects_controller.dart';
import 'package:matricmate/features/exam/models/bookmark_model.dart';
import 'package:matricmate/features/exam/models/question_model.dart';
import 'package:matricmate/utils/helpers/toast_helper.dart';
import 'package:sqflite/sqflite.dart';

class BookmarkController extends GetxController {
  static BookmarkController get instance => Get.find();
  final DatabaseService _databaseService = DatabaseService.instance;

  final RxList<BookmarkModel> bookmarkedQuestionIds = <BookmarkModel>[].obs;
  final RxList<QuestionModel> bookmarkedQuestions = <QuestionModel>[].obs;
  final RxSet<int> bookmarkedIds = <int>{}.obs;
  final RxString searchQuery = ''.obs;

  final RxString languageSelected = "EN".obs;
  final RxBool isQnExpanded = false.obs;

  @override
  void onInit() {
    loadBookmarks();
    super.onInit();
  }

  Future<void> addToBookmark(int qnId) async {
    try {
      final db = await _databaseService.database;
      final bookmarkQn = BookmarkModel(
        questionId: qnId,
        savedAt: DateTime.now().millisecondsSinceEpoch,
      );
      await db.insert(
        'bookmarks',
        bookmarkQn.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      await loadBookmarks();
      ToastHelper.success("Success", "Added to bookmark!");
    } catch (e) {
      ToastHelper.error("Faild!", e.toString());
    }
  }

  Future<void> removeFromBookmark(int qnId) async {
    try {
      final db = await _databaseService.database;
      await db.delete('bookmarks', where: 'question_id = ?', whereArgs: [qnId]);
      await loadBookmarks();
    } catch (e) {
      ToastHelper.error("Faild!", e.toString());
    }
  }

  Future<void> loadBookmarks() async {
    final data = await _databaseService.loadBookmarkedQuestions();

    bookmarkedQuestionIds.value = data;

    bookmarkedIds.value = data.map((b) => b.questionId).toSet();

    final allQns = await _databaseService.getQuestions();

    bookmarkedQuestions.value = data.map((b) {
      final qn = allQns.firstWhere((q) => q['id'] == b.questionId);
      return QuestionModel.fromMap(qn);
    }).toList();
  }

  List<String> get subjects {
    final set = <String>{};

    for (var q in bookmarkedQuestions) {
      set.add(
        SubjectsController.instance.subjects
            .where((s) => s.id == q.subjectId)
            .first
            .name,
      );
    }

    return ["All", ...set];
  }

  String subject(int subjectId) {
    return SubjectsController.instance.subjects
        .where((s) => s.id == subjectId)
        .first
        .name;
  }

  List<QuestionModel> getBySubject(String subject) {
    final query = searchQuery.value.toLowerCase();

    return bookmarkedQuestions.where((q) {
      final matchesSubject =
          subject == "All" ||
          SubjectsController.instance.subjects
                  .firstWhere((s) => s.id == q.subjectId)
                  .name ==
              subject;

      final matchesSearch = q.questionText.toLowerCase().contains(query);

      return matchesSubject && matchesSearch;
    }).toList();
  }

  List<QuestionModel> get filteredQuestions {
    final query = searchQuery.value.toLowerCase();
    if (query.length < 2) return bookmarkedQuestions;

    if (query.isEmpty) return bookmarkedQuestions;

    return bookmarkedQuestions.where((q) {
      return q.questionText.toLowerCase().contains(query);
    }).toList();
  }
}
