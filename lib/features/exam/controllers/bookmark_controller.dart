import 'package:get/get.dart';
import 'package:matricmate/data/database/database_service.dart';
import 'package:matricmate/data/repositories/exam/bookmark_repository.dart';
import 'package:matricmate/data/repositories/exam/question_repository.dart';
import 'package:matricmate/features/exam/controllers/subjects_controller.dart';
import 'package:matricmate/features/exam/models/bookmark_model.dart';
import 'package:matricmate/features/exam/models/passage_model.dart';
import 'package:matricmate/features/exam/models/question_model.dart';
import 'package:matricmate/features/personalization/controllers/user_controller.dart';
import 'package:matricmate/utils/exceptions/exeption_handler.dart';
import 'package:matricmate/utils/helpers/toast_helper.dart';

class BookmarkController extends GetxController {
  static BookmarkController get instance => Get.find();
  final BookmarkRepository _repo = BookmarkRepository();
  final QuestionRepository _questionRepo = QuestionRepository();

  final RxList<BookmarkModel> bookmarkedQuestionIds = <BookmarkModel>[].obs;
  final RxList<QuestionModel> bookmarkedQuestions = <QuestionModel>[].obs;
  final RxSet<int> bookmarkedIds = <int>{}.obs;
  final RxString searchQuery = ''.obs;

  final RxString languageSelected = 'EN'.obs;
  final RxMap<int, bool> isExpanded = <int, bool>{}.obs;
  final RxMap<int, bool> isPassageExpanded = <int, bool>{}.obs;
  final RxMap<int, PassageModel> passages = <int, PassageModel>{}.obs;
  final RxBool isLoading = false.obs;

  // testId → type string cache (populated during loadBookmarks)
  final Map<int, String> _testTypeCache = {};

  /// Returns the display label for a question's test type.
  /// Falls back to 'Unknown' if the test isn't cached yet.
  String testType(int testId) => _testTypeCache[testId] ?? 'Unknown';

  void toggleExpanded(int qnId) {
    isExpanded[qnId] = !(isExpanded[qnId] ?? false);
  }

  void togglePassage(int qnId) {
    isPassageExpanded[qnId] = !(isPassageExpanded[qnId] ?? false);
  }

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
      ToastHelper.success('Added to bookmark!');
    } catch (e) {
      AppExceptionHandler.handleResponse(e);
    }
  }

  Future<void> removeFromBookmark(int qnId) async {
    try {
      await _repo.deleteBookmark(qnId);

      await loadBookmarks();
      ToastHelper.success('Bookmark is removed!');
    } catch (e) {
      AppExceptionHandler.handleResponse(e);
    }
  }

  Future<void> loadBookmarks() async {
    try {
      isLoading.value = true;

      final userId = UserController.instance.user.value.id;
      final data = await _repo.loadBookmarks(userId);
      final allQns = await _repo.getQns();

      // Build the full new list before touching any observables
      final newQuestions = data
          .map((b) {
            final qnList = allQns.where((q) => q['id'] == b.questionId);
            if (qnList.isNotEmpty) return QuestionModel.fromMap(qnList.first);
            return null;
          })
          .whereType<QuestionModel>()
          .toList();

      await _loadPassages(newQuestions);
      await _loadTestTypes(newQuestions);

      // Swap all observables atomically — one rebuild, no flicker
      bookmarkedQuestionIds.value = data;
      // ignore: invalid_use_of_protected_member
      bookmarkedIds.value = data.map((b) => b.questionId).toSet();
      bookmarkedQuestions.value = newQuestions;
    } catch (e) {
      AppExceptionHandler.handleResponse(e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadPassages(List<QuestionModel> questions) async {
    final passageIds = questions
        .where((q) => q.passageId != null)
        .map((q) => q.passageId!)
        .toSet();

    for (final pid in passageIds) {
      if (!passages.containsKey(pid)) {
        try {
          final p = await _questionRepo.getLocalPassage(pid);
          passages[pid] = p;
        } catch (_) {}
      }
    }
  }

  Future<void> _loadTestTypes(List<QuestionModel> questions) async {
    final testIds = questions.map((q) => q.testId).toSet();
    final db = await DatabaseService.instance.database;

    for (final tid in testIds) {
      if (_testTypeCache.containsKey(tid)) continue;
      try {
        final rows = await db.query(
          'tests',
          columns: ['type'],
          where: 'id = ?',
          whereArgs: [tid],
          limit: 1,
        );
        if (rows.isNotEmpty) {
          _testTypeCache[tid] = rows.first['type'] as String? ?? 'Unknown';
        }
      } catch (_) {}
    }
  }

  ///  SAFE SUBJECT LIST
  List<String> get subjects {
    final set = <String>{};

    final subjectsList = SubjectsController.instance.subjects;

    if (subjectsList.isEmpty) return ['All'];

    for (var q in bookmarkedQuestions) {
      final subjectMatch = subjectsList.where((s) => s.id == q.subjectId);

      if (subjectMatch.isNotEmpty) {
        set.add(subjectMatch.first.name);
      }
    }

    return ['All', ...set];
  }

  ///  SAFE SUBJECT NAME
  String subject(int subjectId) {
    final subjectsList = SubjectsController.instance.subjects;

    final match = subjectsList.where((s) => s.id == subjectId);

    return match.isNotEmpty ? match.first.name : 'Unknown';
  }

  ///  FILTER BY SUBJECT + SEARCH
  List<QuestionModel> getBySubject(String subject) {
    final query = searchQuery.value.toLowerCase();
    final subjectsList = SubjectsController.instance.subjects;

    return bookmarkedQuestions.where((q) {
      final subjectMatch = subjectsList.where((s) => s.id == q.subjectId);

      final matchesSubject =
          subject == 'All' ||
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
