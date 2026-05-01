import 'package:get/get.dart';
import 'package:matricmate/data/repositories/exam/bookmark_repository.dart';
import 'package:matricmate/features/exam/controllers/subjects_controller.dart';
import 'package:matricmate/features/exam/models/bookmark_model.dart';
import 'package:matricmate/features/exam/models/question_model.dart';
import 'package:matricmate/features/personalization/controller/user_controller.dart';
import 'package:matricmate/utils/exceptions/exeption_handler.dart';
import 'package:matricmate/utils/helpers/toast_helper.dart';

class BookmarkController extends GetxController {
  static BookmarkController get instance => Get.find();
  final BookmarkRepository _repo = BookmarkRepository();

  final RxList<BookmarkModel> bookmarkedQuestionIds = <BookmarkModel>[].obs;
  final RxList<QuestionModel> bookmarkedQuestions = <QuestionModel>[].obs;
  final RxSet<int> bookmarkedIds = <int>{}.obs;
  final RxString searchQuery = ''.obs;

  final RxString languageSelected = "EN".obs;
  final RxBool isQnExpanded = false.obs;
  final RxBool isLodaing = false.obs;

  @override
  void onInit() {
    loadBookmarks();
    super.onInit();
  }

  Future<void> addToBookmark(int qnId) async {
    try {
      final bookmarkQn = BookmarkModel(
        userId: UserController.instance.user.value.id,
        questionId: qnId,
        savedAt: DateTime.now().millisecondsSinceEpoch,
      );
      await _repo.addBookmark(bookmarkQn);

      await loadBookmarks();
      ToastHelper.success("Added to bookmark!");
    } catch (e) {
      AppExceptionHandler.handleResponse(e);
    }
  }

  Future<void> removeFromBookmark(int qnId) async {
    try {
      await _repo.deleteBookmark(qnId);

      await loadBookmarks();
      ToastHelper.success("Bookmark is removed!");
    } catch (e) {
      AppExceptionHandler.handleResponse(e);
    }
  }

  Future<void> loadBookmarks() async {
    try {
      isLodaing.value = true;

      final data = await _repo.loadBookmarks();

      bookmarkedQuestionIds.value = data
          .where((dt) => dt.userId == UserController.instance.user.value.id)
          .toList();
      // ignore: invalid_use_of_protected_member
      bookmarkedIds.value = data.map((b) => b.questionId).toSet();

      final allQns = await _repo.getQns();

      bookmarkedQuestions.value = data
          .map((b) {
            final qnList = allQns.where((q) => q['id'] == b.questionId);

            if (qnList.isNotEmpty) {
              return QuestionModel.fromMap(qnList.first);
            }

            return null;
          })
          .whereType<QuestionModel>()
          .toList();
    } catch (e) {
      AppExceptionHandler.handleResponse(e);
    } finally {
      isLodaing.value = false;
    }
  }

  ///  SAFE SUBJECT LIST
  List<String> get subjects {
    final set = <String>{};

    final subjectsList = SubjectsController.instance.subjects;

    if (subjectsList.isEmpty) return ["All"];

    for (var q in bookmarkedQuestions) {
      final subjectMatch = subjectsList.where((s) => s.id == q.subjectId);

      if (subjectMatch.isNotEmpty) {
        set.add(subjectMatch.first.name);
      }
    }

    return ["All", ...set];
  }

  ///  SAFE SUBJECT NAME
  String subject(int subjectId) {
    final subjectsList = SubjectsController.instance.subjects;

    final match = subjectsList.where((s) => s.id == subjectId);

    return match.isNotEmpty ? match.first.name : "Unknown";
  }

  ///  FILTER BY SUBJECT + SEARCH
  List<QuestionModel> getBySubject(String subject) {
    final query = searchQuery.value.toLowerCase();
    final subjectsList = SubjectsController.instance.subjects;

    return bookmarkedQuestions.where((q) {
      final subjectMatch = subjectsList.where((s) => s.id == q.subjectId);

      final matchesSubject =
          subject == "All" ||
          (subjectMatch.isNotEmpty && subjectMatch.first.name == subject);

      final matchesSearch = q.questionText.toLowerCase().contains(query);

      return matchesSubject && matchesSearch;
    }).toList();
  }

  ///  SEARCH ONLY
  List<QuestionModel> get filteredQuestions {
    final query = searchQuery.value.toLowerCase();

    if (query.isEmpty || query.length < 2) {
      return bookmarkedQuestions;
    }

    return bookmarkedQuestions.where((q) {
      return q.questionText.toLowerCase().contains(query);
    }).toList();
  }

  void clearSearch() {
    searchQuery.value = '';
  }
}
