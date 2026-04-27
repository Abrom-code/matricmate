import 'package:matricmate/data/database/database_service.dart';
import 'package:matricmate/features/exam/models/chapter_model.dart';
import 'package:matricmate/utils/exceptions/exeption_handler.dart';

class ChapterRepository {
  final DatabaseService _dbService = DatabaseService.instance;

  Future<List<Map<String, dynamic>>> getSubjectChaptersById(
    int subjectId,
  ) async {
    try {
      return await _dbService.getSubjectChapters(subjectId);
    } catch (e) {
      throw AppExceptionHandler.handle(e);
    }
  }

  Future<bool> hasTests(int chapterId) async {
    try {
      return await _dbService.hasTests(chapterId);
    } catch (e) {
      throw AppExceptionHandler.handle(e);
    }
  }

  Future<void> addChapter(ChapterModel chapter) async {
    try {
      await _dbService.insetData('chapters', chapter.toMap());
    } catch (e) {
      throw AppExceptionHandler.handle(e);
    }
  }
}
