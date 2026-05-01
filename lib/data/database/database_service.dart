import 'package:get/get.dart';
import 'package:matricmate/data/database/local_db_schema.dart';
import 'package:matricmate/features/exam/models/bookmark_model.dart';
import 'package:matricmate/features/exam/models/passage_model.dart';
import 'package:matricmate/features/exam/models/result_model.dart';
import 'package:matricmate/features/personalization/controller/user_controller.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseService extends GetxController {
  static Database? _db;
  static DatabaseService get instance => Get.find();

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  Future<Database> _initDB() async {
    final databaseDirPath = await getDatabasesPath();
    final databasePath = join(databaseDirPath, "matricmate.db");

    return await openDatabase(
      databasePath,
      version: 1,
      onCreate: (db, version) async {
        await DBschema.create(db);
      },
    );
  }

  Future<List<Map<String, dynamic>>> getUser() async {
    try {
      final db = await database;
      return db.query('user');
    } catch (e) {
      throw e;
    }
  }

  // Get subjects
  Future<List<Map<String, dynamic>>> getSubjects() async {
    try {
      final db = await database;
      return db.query('subjects');
    } catch (e) {
      throw e;
    }
  }

  Future<List<Map<String, dynamic>>> getChapters() async {
    try {
      final db = await database;
      return db.query('chapters');
    } catch (e) {
      throw e;
    }
  }

  Future<List<Map<String, dynamic>>> getQuestions() async {
    try {
      final db = await database;
      return db.query('questions');
    } catch (e) {
      throw e;
    }
  }

  Future<List<Map<String, dynamic>>> getDownloadedSubjects() async {
    try {
      final db = await database;
      return db.rawQuery('SELECT * FROM subjects WHERE is_downloaded = 1');
    } catch (e) {
      throw e;
    }
  }

  // Get subject chapters
  Future<List<Map<String, dynamic>>> getSubjectChapters(int subjectId) async {
    try {
      final db = await database;
      return db.rawQuery('SELECT * FROM chapters WHERE subject_id =?', [
        subjectId,
      ]);
    } catch (e) {
      throw e;
    }
  }

  // Get Subject tests
  Future<List<Map<String, dynamic>>> getTests({
    required int subjectId,
    int? grade,
    String? type,
  }) async {
    try {
      final db = await database;

      String query = 'SELECT * FROM tests WHERE subject_id = ?';
      List<dynamic> args = [subjectId];

      if (type != null) {
        query += ' AND type = ?';
        args.add(type);
      }

      if (grade != null) {
        query += ' AND grade = ?';
        args.add(grade);
      }

      return db.rawQuery(query, args);
    } catch (e) {
      rethrow;
    }
  }

  // Get subject questions
  Future<List<Map<String, dynamic>>> getAllSubjectQuestions(
    String subject,
  ) async {
    try {
      final db = await database;
      return db.rawQuery(
        'SELECT * FROM questions WHERE subject_id = (SELECT id FROM subjects WHERE name = ?)',
        [subject],
      );
    } catch (e) {
      throw e;
    }
  }

  // Get tests by subject
  Future<List<Map<String, dynamic>>> getTestsBySubject(int subjectId) async {
    try {
      final db = await database;

      return db.query('tests', where: 'subject_id = ?', whereArgs: [subjectId]);
    } catch (e) {
      throw e;
    }
  }

  // load questions for test
  Future<List<Map<String, dynamic>>> getQuestionsByTest(int testId) async {
    try {
      final db = await database;

      return db.query(
        'questions',
        where: 'test_id = ?',
        whereArgs: [testId],
        orderBy: 'question_order ASC',
      );
    } catch (e) {
      throw e;
    }
  }

  Future<bool> hasTests(int chapterId) async {
    try {
      final db = await database;

      final result = await db.query(
        'tests',
        where: 'chapter_id = ?',
        whereArgs: [chapterId],
        limit: 1,
      );
      return result.isNotEmpty;
    } catch (e) {
      throw e;
    }
  }

  Future<bool> hasQuestions(int testId) async {
    try {
      final db = await database;

      final result = await db.query(
        'questions',
        where: 'test_id = ?',
        whereArgs: [testId],
        limit: 1,
      );
      return result.isNotEmpty;
    } catch (e) {
      throw e;
    }
  }

  Future<ResultModel?> loadSavedTestResult(int testId) async {
    try {
      final db = await database;
      final result = await db.query(
        'results',
        where: 'test_id = ?',
        whereArgs: [testId],
        limit: 1,
      );
      if (result.isEmpty) return null;

      return ResultModel.fromMap(result.first);
    } catch (e) {
      throw e;
    }
  }

  Future<List<BookmarkModel>> loadBookmarkedQuestions() async {
    try {
      final db = await database;
      final result = await db.query('bookmarks', orderBy: 'saved_at DESC');

      return result.map((res) => BookmarkModel.fromMap(res)).toList();
    } catch (e) {
      throw e;
    }
  }

  Future<int> getCompletedTests() async {
    try {
      final db = await database;
      final result = await db.query('results');

      return result
          .where((r) => r['user_id'] == UserController.instance.user.value.id)
          .length;
    } catch (e) {
      throw e;
    }
  }

  Future<int> getETestNumbers(int subjectId, String type) async {
    try {
      final db = await database;
      final result = await db.query(
        'tests',
        where: 'type = ? AND subject_id = ?',
        whereArgs: [type, subjectId],
      );
      return result.length;
    } catch (e) {
      rethrow;
    }
  }

  Future<PassageModel> getPassage(int? pId) async {
    try {
      final db = await database;

      if (pId == null) {
        return PassageModel(id: -1, content: "", title: "");
      }

      final result = await db.query(
        'passages',
        where: 'id = ?',
        whereArgs: [pId],
        limit: 1,
      );

      if (result.isEmpty) {
        return PassageModel(
          id: -1,
          content: "No passage found",
          title: "Missing",
        );
      }

      return PassageModel.fromMap(result.first);
    } catch (e) {
      throw e;
    }
  }

  /// DatabaseService.dart

  Future<void> clearAllData() async {
    try {
      final db = await instance.database;

      await db.transaction((txn) async {
        await txn.delete('subjects');

        await txn.delete('passages');
        await txn.delete('results');
        await txn.delete('bookmarks');
        await txn.delete('user');
      });
    } catch (e) {
      throw e;
    }
  }

  Future<void> insetData(String table, Map<String, dynamic> value) async {
    try {
      final db = await instance.database;
      await db.insert(
        table,
        value,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      throw e;
    }
  }
}
