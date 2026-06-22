import 'package:matricmate/data/database/database_service.dart';
import 'package:matricmate/features/exam/models/bookmark_model.dart';
import 'package:matricmate/utils/exceptions/exeption_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BookmarkRepository {
  final SupabaseClient supabase = Supabase.instance.client;
  final DatabaseService _dbService = DatabaseService.instance;

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
