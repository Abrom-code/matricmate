import 'package:get/get.dart';
import 'package:matricmate/data/database/local_db_schema.dart';
import 'package:matricmate/features/exam/models/result_model.dart';
import 'package:matricmate/utils/logging/logging.dart';
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

  // Get subjects
  Future<List<Map<String, dynamic>>> getSubjects() async {
    final db = await database;
    return db.query('subjects');
  }

  Future<List<Map<String, dynamic>>> getChapters() async {
    final db = await database;
    return db.query('chapters');
  }

  Future<List<Map<String, dynamic>>> getTests() async {
    final db = await database;
    return db.query('tests');
  }

  Future<List<Map<String, dynamic>>> getQuestions() async {
    final db = await database;
    return db.query('questions');
  }

  Future<List<Map<String, dynamic>>> getDownloadedSubjects() async {
    final db = await database;
    return db.rawQuery('SELECT * FROM subjects WHERE is_downloaded = 1');
  }

  // Get subject chapters
  Future<List<Map<String, dynamic>>> getSubjectChapters(int subjectId) async {
    final db = await database;
    return db.rawQuery('SELECT * FROM chapters WHERE subject_id =?', [
      subjectId,
    ]);
  }

  // Get Subject tests
  Future<List<Map<String, dynamic>>> getSubjectTests(int subjectId) async {
    final db = await database;
    return db.rawQuery(
      'SELECT * FROM tests WHERE subject_id = (SELECT id FROM subjects WHERE id = ?)',
      [subjectId],
    );
  }

  // Get subject questions
  Future<List<Map<String, dynamic>>> getAllSubjectQuestions(
    String subject,
  ) async {
    final db = await database;
    return db.rawQuery(
      'SELECT * FROM questions WHERE subject_id = (SELECT id FROM subjects WHERE name = ?)',
      [subject],
    );
  }

  // Get tests by subject
  Future<List<Map<String, dynamic>>> getTestsBySubject(int subjectId) async {
    final db = await database;

    return db.query('tests', where: 'subject_id = ?', whereArgs: [subjectId]);
  }

  // load questions for test
  Future<List<Map<String, dynamic>>> getQuestionsByTest(int testId) async {
    final db = await database;

    return db.query(
      'questions',
      where: 'test_id = ?',
      whereArgs: [testId],
      orderBy: 'question_order ASC',
    );
  }

  Future<bool> hasTests(int chapterId) async {
    final db = await database;

    final result = await db.query(
      'tests',
      where: 'chapter_id = ?',
      whereArgs: [chapterId],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  Future<bool> hasQuestions(int testId) async {
    final db = await database;

    final result = await db.query(
      'questions',
      where: 'test_id = ?',
      whereArgs: [testId],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  Future<ResultModel?> loadSavedTestResult(int testId) async {
    final db = await database;
    final result = await db.query(
      'results',
      where: 'test_id = ?',
      whereArgs: [testId],
      limit: 1,
    );
    if (result.isEmpty) return null;

    return ResultModel.fromMap(result.first);
  }

  // For future versions!

  // Start test
  Future<int> startTest({
    required int testId,
    required int totalQuestions,
  }) async {
    final db = await database;

    return db.insert('test_progress', {
      'test_id': testId,
      'total_questions': totalQuestions,
      'questions_attempted': 0,
      'status': 'in_progress',
      'started_at': DateTime.now().toIso8601String(),
    });
  }

  // Save answers
  Future<void> saveAnswer({
    required int testProgressId,
    required int questionId,
    required int selectedOption,
    required int correctOption,
    required int currentIndex,
  }) async {
    final db = await database;

    final isCorrect = selectedOption == correctOption ? 1 : 0;

    await db.insert('question_answers', {
      'test_progress_id': testProgressId,
      'question_id': questionId,
      'selected_option_index': selectedOption,
      'is_correct': isCorrect,
      'answered_at': DateTime.now().toIso8601String(),
    });

    // update progress
    await db.rawUpdate(
      '''
    UPDATE test_progress
    SET 
      questions_attempted = questions_attempted + 1,
      last_question_id = ?,
      updated_at = ?
    WHERE id = ?
  ''',
      [questionId, DateTime.now().toIso8601String(), testProgressId],
    );
  }

  // Get test progress
  Future<Map<String, dynamic>?> getTestProgress(int testId) async {
    final db = await database;

    final result = await db.query(
      'test_progress',
      where: 'test_id = ?',
      whereArgs: [testId],
      orderBy: 'id DESC',
      limit: 1,
    );

    if (result.isNotEmpty) return result.first;
    return null;
  }

  // Get answers
  Future<List<Map<String, dynamic>>> getAnswers(int testProgressId) async {
    final db = await database;

    return db.query(
      'question_answers',
      where: 'test_progress_id = ?',
      whereArgs: [testProgressId],
    );
  }

  // Complete test
  Future<void> completeTest(int testProgressId) async {
    final db = await database;

    await db.update(
      'test_progress',
      {'status': 'completed', 'completed_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [testProgressId],
    );
  }

  // calulate progress
  double calculateProgress(int attempted, int total) {
    if (total == 0) return 0;
    return attempted / total;
  }

  // get correct answers
  Future<int> getCorrectAnswers(int testProgressId) async {
    final db = await database;

    final result = await db.rawQuery(
      '''
    SELECT COUNT(*) as correct_count
    FROM question_answers
    WHERE test_progress_id = ? AND is_correct = 1
  ''',
      [testProgressId],
    );

    return result.first['correct_count'] as int;
  }
}
