import 'dart:convert';
import 'package:get/get.dart';
import 'package:matricmate/data/database/local_db_schema.dart';
import 'package:matricmate/features/exam/models/bookmark_model.dart';
import 'package:matricmate/features/exam/models/passage_model.dart';
import 'package:matricmate/features/exam/models/result_model.dart';
import 'package:matricmate/features/personalization/controllers/user_controller.dart';
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
      version: 14,
      onCreate: (db, version) async {
        await DBschema.create(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 3) {
          for (final sql in [
            'ALTER TABLE questions ADD COLUMN section_id INTEGER',
            'ALTER TABLE questions ADD COLUMN section_title TEXT',
          ]) {
            try {
              await db.execute(sql);
            } catch (_) {}
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
          // Recreate results table with composite UNIQUE(user_id, test_id)
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
            // Copy existing rows; keep only most recent per (user_id, test_id)
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
        if (oldVersion < 9) {
          // Add notifications table for users upgrading from DB v1–8
          try {
            await db.execute('''
              CREATE TABLE IF NOT EXISTS notifications (
                id INTEGER PRIMARY KEY,
                user_id TEXT NOT NULL,
                title TEXT NOT NULL,
                body TEXT NOT NULL,
                type TEXT NOT NULL DEFAULT 'announcement',
                payload TEXT,
                target_stream TEXT,
                is_read INTEGER DEFAULT 0,
                created_at TEXT NOT NULL
              )
            ''');
            await db.execute(
              'CREATE INDEX IF NOT EXISTS idx_notifications_user '
              'ON notifications(user_id, created_at)',
            );
          } catch (_) {}
        }
        if (oldVersion < 10) {
          // Add created_at to user table for notification filtering
          try {
            await db.execute('ALTER TABLE user ADD COLUMN created_at TEXT');
          } catch (_) {}
          // Track dismissed notifications to avoid re-inserting during sync
          try {
            await db.execute('''
              CREATE TABLE IF NOT EXISTS notification_dismissals (
                notification_id INTEGER NOT NULL,
                user_id TEXT NOT NULL,
                dismissed_at TEXT NOT NULL DEFAULT (datetime('now')),
                PRIMARY KEY (notification_id, user_id)
              )
            ''');
            await db.execute(
              'CREATE INDEX IF NOT EXISTS idx_dismissals_user '
              'ON notification_dismissals(user_id)',
            );
          } catch (_) {}
        }
        if (oldVersion < 11) {
          // Add target_stream column if upgrading from v9/10
          try {
            await db.execute(
              'ALTER TABLE notifications ADD COLUMN target_stream TEXT',
            );
          } catch (_) {}
        }
        if (oldVersion < 12) {
          // Add receipt_upload_count to user table
          try {
            await db.execute(
              'ALTER TABLE user ADD COLUMN receipt_upload_count INTEGER DEFAULT 0',
            );
          } catch (_) {}
        }
        if (oldVersion < 13) {
          // Add subscription_plan and subscription_expires_at to user table
          try {
            await db.execute('ALTER TABLE user ADD COLUMN subscription_plan TEXT');
          } catch (_) {}
          try {
            await db.execute(
              'ALTER TABLE user ADD COLUMN subscription_expires_at TEXT',
            );
          } catch (_) {}
        }
        if (oldVersion < 14) {
          // Add local challenge tables for offline practice
          try {
            await db.execute('''
              CREATE TABLE IF NOT EXISTS local_challenge_sets (
                id TEXT PRIMARY KEY,
                challenge_id TEXT NOT NULL,
                subject_id INTEGER NOT NULL,
                title TEXT NOT NULL,
                audience TEXT DEFAULT 'both',
                downloaded_at TEXT NOT NULL
              )
            ''');
            await db.execute('''
              CREATE TABLE IF NOT EXISTS local_challenge_questions (
                id TEXT PRIMARY KEY,
                set_id TEXT NOT NULL,
                order_index INTEGER NOT NULL,
                question_text TEXT NOT NULL,
                choices TEXT NOT NULL,
                correct_choice TEXT NOT NULL,
                explanation TEXT,
                image_url TEXT,
                FOREIGN KEY(set_id) REFERENCES local_challenge_sets(id) ON DELETE CASCADE
              )
            ''');
            await db.execute(
              'CREATE INDEX IF NOT EXISTS idx_local_challenge_questions_set '
              'ON local_challenge_questions(set_id, order_index)',
            );
          } catch (_) {}
        }
      },
      onOpen: (db) async {
        try {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS local_challenge_sets (
              id TEXT PRIMARY KEY,
              challenge_id TEXT NOT NULL,
              subject_id INTEGER NOT NULL,
              title TEXT NOT NULL,
              audience TEXT DEFAULT 'both',
              downloaded_at TEXT NOT NULL
            )
          ''');
          await db.execute('''
            CREATE TABLE IF NOT EXISTS local_challenge_questions (
              id TEXT PRIMARY KEY,
              set_id TEXT NOT NULL,
              order_index INTEGER NOT NULL,
              question_text TEXT NOT NULL,
              choices TEXT NOT NULL,
              correct_choice TEXT NOT NULL,
              explanation TEXT,
              explanation_en TEXT,
              explanation_am TEXT,
              image_url TEXT
            )
          ''');
        } catch (_) {}
      },
    );
  }

  Future<List<Map<String, dynamic>>> getUser() async {
    try {
      final db = await database;
      return await db.query('user');
    } catch (e) {
      rethrow;
    }
  }

  // Get subjects
  Future<List<Map<String, dynamic>>> getSubjects() async {
    try {
      final db = await database;
      return await db.query('subjects');
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getChapters() async {
    try {
      final db = await database;
      return await db.query('chapters');
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getQuestions() async {
    try {
      final db = await database;
      return await db.query('questions');
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getDownloadedSubjects() async {
    try {
      final db = await database;
      return await db.rawQuery(
        'SELECT * FROM subjects WHERE is_downloaded = 1',
      );
    } catch (e) {
      rethrow;
    }
  }

  // Get subject chapters
  Future<List<Map<String, dynamic>>> getSubjectChapters(int subjectId) async {
    try {
      final db = await database;
      return await db.rawQuery('SELECT * FROM chapters WHERE subject_id =?', [
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

      return await db.rawQuery(query, args);
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
      return await db.rawQuery(
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

      return await db.query(
        'tests',
        where: 'subject_id = ?',
        whereArgs: [subjectId],
      );
    } catch (e) {
      rethrow;
    }
  }

  // load questions for test
  Future<List<Map<String, dynamic>>> getQuestionsByTest(int testId) async {
    try {
      final db = await database;

      return await db.query(
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

  /// Returns most recent in-progress draft for the current user.
  Future<Map<String, dynamic>?> loadMostRecentInProgressResult({
    List<String>? types,
  }) async {
    try {
      final db = await database;
      final userId = UserController.instance.user.value.id;

      String typeFilter = '';
      List<Object?> args = [userId];

      if (types != null && types.isNotEmpty) {
        final placeholders = types.map((_) => '?').join(', ');
        typeFilter = 'AND t.type IN ($placeholders)';
        args = [userId, ...types];
      }

      final rows = await db.rawQuery('''
        SELECT r.*, t.title AS test_title, t.time AS test_time, t.id AS t_id
        FROM results r
        JOIN tests t ON r.test_id = t.id
        WHERE r.user_id = ? AND r.isCompleted = 0
        $typeFilter
        ORDER BY r.rowid DESC
        LIMIT 1
        ''', args);
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

  Future<void> clearAllData() async {
    try {
      final db = await instance.database;

      await db.transaction((txn) async {
        await txn.delete('bookmarks');
        await txn.delete('notifications');
        await txn.delete('notification_dismissals');
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

  /// Returns all in-progress drafts for the current user with test/subject info.
  Future<List<Map<String, dynamic>>> loadAllInProgressResults() async {
    try {
      final db = await database;
      final userId = UserController.instance.user.value.id;

      return await db.rawQuery(
        '''
        SELECT r.*, t.title AS test_title, t.time AS test_time,
               t.type AS test_type, s.name AS subject_name
        FROM results r
        JOIN tests t ON r.test_id = t.id
        LEFT JOIN subjects s ON t.subject_id = s.id
        WHERE r.user_id = ? AND r.isCompleted = 0
        ORDER BY r.rowid DESC
        ''',
        [userId],
      );
    } catch (e) {
      rethrow;
    }
  }

  // ── Offline Challenge Bundle Helpers ─────────────────────────────────────

  Future<void> insertDownloadedChallengeBundle(Map<String, dynamic> bundle) async {
    final db = await database;
    await db.transaction((txn) async {
      final challengeId = bundle['challenge_id']?.toString() ?? bundle['id']?.toString() ?? '';
      final subjectId = (bundle['subject_id'] as num?)?.toInt() ?? 0;
      final title = bundle['title']?.toString() ?? 'Challenge Set';
      final audience = bundle['audience']?.toString() ?? 'both';

      await txn.insert(
        'local_challenge_sets',
        {
          'id': challengeId,
          'challenge_id': challengeId,
          'subject_id': subjectId,
          'title': title,
          'audience': audience,
          'downloaded_at': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      final questions = bundle['questions'];
      if (questions is List) {
        for (final q in questions) {
          final choices = q['choices'];
          String choicesStr = '[]';
          if (choices is List) {
            choicesStr = jsonEncode(choices);
          } else if (choices is String) {
            choicesStr = choices;
          }

          final explEn = q['explanation_en']?.toString() ?? q['explanation']?.toString() ?? '';
          final explAm = q['explanation_am']?.toString() ?? '';

          await txn.insert(
            'local_challenge_questions',
            {
              'id': q['id']?.toString() ?? '',
              'set_id': challengeId,
              'order_index': (q['order_index'] as num?)?.toInt() ?? 1,
              'question_text': q['question_text']?.toString() ?? '',
              'choices': choicesStr,
              'correct_choice': q['correct_choice']?.toString() ?? '',
              'explanation': explEn,
              'explanation_en': explEn,
              'explanation_am': explAm,
              'image_url': q['image_url']?.toString(),
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }
    });
  }

  Future<List<Map<String, dynamic>>> getDownloadedChallengeSets({int? subjectId}) async {
    final db = await database;
    if (subjectId != null) {
      return await db.query(
        'local_challenge_sets',
        where: 'subject_id = ?',
        whereArgs: [subjectId],
        orderBy: 'downloaded_at DESC',
      );
    }
    return await db.query('local_challenge_sets', orderBy: 'downloaded_at DESC');
  }

  Future<List<Map<String, dynamic>>> getDownloadedChallengeQuestions(String challengeId) async {
    final db = await database;
    return await db.query(
      'local_challenge_questions',
      where: 'set_id = ? OR id = ?',
      whereArgs: [challengeId, challengeId],
      orderBy: 'order_index ASC',
    );
  }

  Future<bool> isChallengeDownloaded(String challengeId, {String? setId}) async {
    final db = await database;
    final ids = [challengeId, if (setId != null && setId.isNotEmpty) setId];
    final placeholders = List.filled(ids.length, '?').join(',');
    final res = await db.query(
      'local_challenge_sets',
      where: 'challenge_id IN ($placeholders) OR id IN ($placeholders)',
      whereArgs: [...ids, ...ids],
      limit: 1,
    );
    return res.isNotEmpty;
  }

  Future<void> deleteDownloadedChallenge(String challengeId, {String? setId}) async {
    final db = await database;
    await db.transaction((txn) async {
      try {
        await txn.delete(
          'local_challenge_practice',
          where: 'challenge_id = ?',
          whereArgs: [challengeId],
        );
      } catch (_) {}
      final ids = {challengeId, if (setId != null && setId.isNotEmpty) setId};
      for (final id in ids) {
        await txn.delete(
          'local_challenge_questions',
          where: 'set_id = ? OR id = ?',
          whereArgs: [id, id],
        );
        await txn.delete(
          'local_challenge_sets',
          where: 'id = ? OR challenge_id = ?',
          whereArgs: [id, id],
        );
      }
    });
  }
  // ── Practice results persistence ──────────────────────────────────────────
  Future<void> saveChallengePracticeResult({
    required String challengeId,
    required int score,
    required int totalQuestions,
    required Map<String, String> userAnswers,
    int? timeSpentSeconds,
  }) async {
    final db = await database;
    try {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS local_challenge_practice (
          challenge_id TEXT PRIMARY KEY,
          score INTEGER NOT NULL,
          total_questions INTEGER NOT NULL,
          time_spent_seconds INTEGER,
          user_answers TEXT NOT NULL,
          completed_at TEXT NOT NULL
        )
      ''');
    } catch (_) {}

    await db.insert(
      'local_challenge_practice',
      {
        'challenge_id': challengeId,
        'score': score,
        'total_questions': totalQuestions,
        'time_spent_seconds': timeSpentSeconds ?? 0,
        'user_answers': jsonEncode(userAnswers),
        'completed_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, dynamic>?> getChallengePracticeResult(String challengeId) async {
    final db = await database;
    try {
      final res = await db.query(
        'local_challenge_practice',
        where: 'challenge_id = ?',
        whereArgs: [challengeId],
        limit: 1,
      );
      if (res.isNotEmpty) {
        return res.first;
      }
    } catch (_) {}
    return null;
  }

  Future<Set<String>> getCompletedPracticeChallengeIds() async {
    final db = await database;
    try {
      final res = await db.query(
        'local_challenge_practice',
        columns: ['challenge_id'],
      );
      return res.map((r) => r['challenge_id']?.toString() ?? '').where((id) => id.isNotEmpty).toSet();
    } catch (_) {
      return {};
    }
  }
}
