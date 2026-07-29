import 'package:matricmate/data/database/database_service.dart';
import 'package:matricmate/features/exam/models/bookmark_model.dart';
import 'package:matricmate/utils/exceptions/exception_handler.dart';

class BookmarkRepository {
  BookmarkRepository({DatabaseService? databaseService})
    : _dbService = databaseService ?? DatabaseService.instance;

  final DatabaseService _dbService;

  Future<void> addBookmark(BookmarkModel bookmarkQn) async {
    try {
      await _dbService.insetData('bookmarks', bookmarkQn.toMap());
    } catch (e) {
      throw AppExceptionHandler.handle(e);
    }
  }

  Future<void> deleteBookmark(int qnId) async {
    try {
      final db = await _dbService.database;
      await db.delete('bookmarks', where: 'question_id = ?', whereArgs: [qnId]);
    } catch (e) {
      throw AppExceptionHandler.handle(e);
    }
  }

  Future<List<BookmarkModel>> loadBookmarks(String userId) async {
    try {
      return await _dbService.loadBookmarkedQuestions(userId);
    } catch (e) {
      throw AppExceptionHandler.handle(e);
    }
  }

  Future<List<Map<String, dynamic>>> getQns() async {
    try {
      return await _dbService.getQuestions();
    } catch (e) {
      throw AppExceptionHandler.handle(e);
    }
  }
}
