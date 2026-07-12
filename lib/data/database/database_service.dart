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
    final databasePath = join(databaseDirPath, 'matricmate.db');

    return await openDatabase(
      databasePath,
      version: 8,
      onCreate: (db, version) async {
        await DBschema.create(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 3) {
          for (final sql in [
            'ALTER TABLE questions ADD COLUMN section_id INTEGER',
            'ALTER TABLE questions ADD COLUMN section_title TEXT',
          ]) {
            try { await db.execute(sql); } catch (_) {}
          }
        }
        if (oldVersion < 4) {
          try {
            await db.execute(
              'ALTER TABLE subjects ADD COLUMN is_entrance_downloaded INTEGER DEFAULT 0',
            );
          } catch (_) {}
        }
        if (oldVersion < 5) {
          try {
            await db.execute(
              'ALTER TABLE questions ADD COLUMN explanation_image_url TEXT',
            );
          } catch (_) {}
        }
        if (oldVersion < 6) {
          try {
            await db.execute(
              'ALTER TABLE results ADD COLUMN isCompleted INTEGER DEFAULT 1',
            );
          } catch (_) {}
          try {
            await db.execute(
              'ALTER TABLE results ADD COLUMN checkedQuestions TEXT',
            );
          } catch (_) {}
          try {
            await db.execute(
              'ALTER TABLE results ADD COLUMN remainingSeconds INTEGER DEFAULT 0',
            );
          } catch (_) {}
        }
        if (oldVersion < 7) {
          try {
            await db.execute(
              'ALTER TABLE subjects ADD COLUMN entrance_count INTEGER DEFAULT 0',
            );
          } catch (_) {}
          try {
            await db.execute(
              'ALTER TABLE subjects ADD COLUMN model_count INTEGER DEFAULT 0',
            );
          } catch (_) {}
        }
        if (oldVersion < 8) {
          // Recreate results table with a composite UNIQUE(user_id, test_id)
          // instead of the old test_id UNIQUE which allowed one user's result
          // to overwrite another's and caused cross-test paused-state bleed.
          await db.transaction((txn) async {
            await txn.execute('''
              CREATE TABLE results_new (
                user_id TEXT NOT NULL,
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                test_id INTEGER NOT NULL,
                testQuestions TEXT,
                selectedAnswers TEXT,
                correctAnswers INTEGER,
                isCompleted INTEGER DEFAULT 1,
                checkedQuestions TEXT,
                remainingSeconds INTEGER DEFAULT 0,
                UNIQUE(user_id, test_id)
              )
            ''');
            // Copy existing rows; keep only the most recent per (user_id, test_id)
            // in case of duplicate test_ids from the old schema.
            await txn.execute('''
              INSERT OR IGNORE INTO results_new
                (user_id, test_id, testQuestions, selectedAnswers,
                 correctAnswers, isCompleted, checkedQuestions, remainingSeconds)
              SELECT user_id, test_id, testQuestions, selectedAnswers,
                     correctAnswers, isCompleted, checkedQuestions, remainingSeconds
              FROM results
              ORDER BY id DESC
            ''');
            await txn.execute('DROP TABLE results');
            await txn.execute('ALTER TABLE results_new RENAME TO results');
          });
        }
      },
      // Ensure the column exists even on devices that somehow missed onUpgrade
      onOpen: (db) async {
        try {
          await db.execute(
            'ALTER TABLE results ADD COLUMN isCompleted INTEGER DEFAULT 1',
          );
        } catch (_) {}
        try {
          await db.execute(
            'ALTER TABLE results ADD COLUMN checkedQuestions TEXT',
          );
        } catch (_) {}
        try {
          await db.execute(
            'ALTER TABLE results ADD COLUMN remainingSeconds INTEGER DEFAULT 0',
          );
        } catch (_) {}
        try {
          await db.execute(
            'ALTER TABLE subjects ADD COLUMN entrance_count INTEGER DEFAULT 0',
          );
        } catch (_) {}
        try {
          await db.execute(
            'ALTER TABLE subjects ADD COLUMN model_count INTEGER DEFAULT 0',
          );
        } catch (_) {}
      },
    );
  }

  Future<List<Map<String, dynamic>>> getUser() async {
    try {
      final db = await database;
      return db.query('user');
    } catch (e) {
      rethrow;
    }
  }

  // Get subjects
  Future<List<Map<String, dynamic>>> getSubjects() async {
    try {
      final db = await database;
      return db.query('subjects');
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getChapters() async {
    try {
      final db = await database;
      return db.query('chapters');
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getQuestions() async {
    try {
      final db = await database;
      return db.query('questions');
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getDownloadedSubjects() async {
    try {
      final db = await database;
      return db.rawQuery('SELECT * FROM subjects WHERE is_downloaded = 1');
    } catch (e) {
      rethrow;
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
      rethrow;
    }
  }

  // Get Subject tests
  Future<List<Map<String, dynamic>>> getTests({
    required int subjectId,
    int? grade,
    String? type,
    int? chapterId,
  }) async {
    try {
      final db = await database;

      String query = 'SELECT * FROM tests WHERE subject_id = ?';
      final List<dynamic> args = [subjectId];

      if (type != null) {
        query += ' AND type = ?';
        args.add(type);
      }

      if (grade != null) {
        query += ' AND grade = ?';
        args.add(grade);
      }

      if (chapterId != null) {
        query += ' AND chapter_id = ?';
        args.add(chapterId);
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
      rethrow;
    }
  }

  // Get tests by subject
  Future<List<Map<String, dynamic>>> getTestsBySubject(int subjectId) async {
    try {
      final db = await database;

      return db.query('tests', where: 'subject_id = ?', whereArgs: [subjectId]);
    } catch (e) {
      rethrow;
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
      rethrow;
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
      rethrow;
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
      rethrow;
    }
  }

  Future<ResultModel?> loadSavedTestResult(int testId) async {
    try {
      final db = await database;
      final userId = UserController.instance.user.value.id;
      final result = await db.query(
        'results',
        where: 'test_id = ? AND user_id = ?',
        whereArgs: [testId, userId],
        limit: 1,
      );
      if (result.isEmpty) return null;

      return ResultModel.fromMap(result.first);
    } catch (e) {
      rethrow;
    }
  }

  /// Returns the most recent in-progress draft (isCompleted = 0) for the
  /// current user, joined with its test title and time for display.
  Future<Map<String, dynamic>?> loadMostRecentInProgressResult() async {
    try {
      final db = await database;
      final userId = UserController.instance.user.value.id;
      final rows = await db.rawQuery(
        '''
        SELECT r.*, t.title AS test_title, t.time AS test_time, t.id AS t_id
        FROM results r
        JOIN tests t ON r.test_id = t.id
        WHERE r.user_id = ? AND r.isCompleted = 0
        ORDER BY r.rowid DESC
        LIMIT 1
        ''',
        [userId],
      );
      if (rows.isEmpty) return null;
      return rows.first;
    } catch (e) {
      rethrow;
    }
  }

  Future<List<BookmarkModel>> loadBookmarkedQuestions(String userId) async {
    try {
      final db = await database;
      final result = await db.query(
        'bookmarks',
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'saved_at DESC',
      );

      return result.map((res) => BookmarkModel.fromMap(res)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<int> getCompletedTests() async {
    try {
      final db = await database;
      final userId = UserController.instance.user.value.id;
      final result = await db.query(
        'results',
        where: 'user_id = ?',
        whereArgs: [userId],
      );
      return result.length;
    } catch (e) {
      rethrow;
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
        return PassageModel(id: -1, content: '', title: '');
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
          content: 'No passage found',
          title: 'Missing',
        );
      }

      return PassageModel.fromMap(result.first);
    } catch (e) {
      rethrow;
    }
  }

  /// DatabaseService.dart

  Future<void> clearAllData() async {
    try {
      final db = await instance.database;

      await db.transaction((txn) async {
        await txn.delete('bookmarks');
        await txn.delete('results');
        await txn.delete('questions');
        await txn.delete('passages');
        await txn.delete('tests');
        await txn.delete('chapters');
        await txn.delete('subjects');
        await txn.delete('user');
      });
    } catch (e) {
      rethrow;
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
      rethrow;
    }
  }

  /// Upserts a test result row, matching on (user_id, test_id).
  /// Uses ConflictAlgorithm.replace so a draft can be overwritten by a
  /// completed result and vice-versa for the same user+test combination.
  Future<void> saveResult(ResultModel result) async {
    try {
      final db = await instance.database;
      await db.insert(
        'results',
        result.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      rethrow;
    }
  }
}
