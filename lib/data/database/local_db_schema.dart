import 'package:sqflite/sqflite.dart';

class DBschema {
  static Future<void> create(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');

    await db.execute('''
      CREATE TABLE user(
        id TEXT PRIMARY KEY,
        first_name TEXT NOT NULL,
        last_name TEXT,
        email TEXT NOT NULL,
        stream TEXT
      );
    ''');

    await db.execute('''
      CREATE TABLE subjects (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL UNIQUE,
        is_natural INTEGER NOT NULL,
        is_common INTEGER DEFAULT 0,
        is_downloaded INTEGER DEFAULT 0
      );
    ''');

    await db.execute('''
      CREATE TABLE chapters (
        id INTEGER PRIMARY KEY,
        subject_id INTEGER NOT NULL,
        grade INTEGER NOT NULL,
        chapter_number INTEGER NOT NULL,
        title TEXT NOT NULL,
        FOREIGN KEY(subject_id) REFERENCES subjects(id) ON DELETE CASCADE
      );
    ''');

    await db.execute('''
      CREATE TABLE passages (
        id INTEGER PRIMARY KEY,
        content TEXT NOT NULL,
        image_url TEXT
      );
    ''');

    await db.execute('''
      CREATE TABLE tests (
        id INTEGER PRIMARY KEY,
        subject_id INTEGER NOT NULL,
        grade INTEGER,
        chapter_id INTEGER,
        title TEXT NOT NULL,
        type TEXT NOT NULL DEFAULT 'chapter',
        question_count INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY(subject_id) REFERENCES subjects(id) ON DELETE CASCADE,
        FOREIGN KEY(chapter_id) REFERENCES chapters(id) ON DELETE CASCADE
      );
    ''');

    await db.execute('''
      CREATE TABLE questions (
        id INTEGER PRIMARY KEY,
        subject_id INTEGER NOT NULL,
        grade INTEGER NOT NULL,
        chapter_id INTEGER,
        test_id INTEGER NOT NULL,
        passage_id INTEGER,
        question_text TEXT NOT NULL,
        image_url TEXT,
        options TEXT NOT NULL,
        correct_option_index INTEGER NOT NULL,
        explanation_en TEXT,
        explanation_am TEXT,
        question_order INTEGER DEFAULT 1,

        FOREIGN KEY(subject_id) REFERENCES subjects(id) ON DELETE CASCADE,
        FOREIGN KEY(chapter_id) REFERENCES chapters(id) ON DELETE SET NULL,
        FOREIGN KEY(test_id) REFERENCES tests(id) ON DELETE CASCADE,
        FOREIGN KEY(passage_id) REFERENCES passages(id) ON DELETE SET NULL
      );
    ''');

    await db.execute('''
      CREATE TABLE results (
        user_id TEXT NOT NULL,
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        test_id INTEGER UNIQUE,
        testQuestions TEXT,
        selectedAnswers TEXT,
        correctAnswers INTEGER
      );
    ''');
    await db.execute('''
      CREATE TABLE bookmarks (
        user_id TEXT NOT NULL,
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        question_id INTEGER UNIQUE,
        saved_at INTEGER NOT NULL
        );
''');

    await db.execute(
      'CREATE INDEX idx_questions_subject_grade ON questions(subject_id, grade)',
    );

    await db.execute(
      'CREATE INDEX idx_questions_chapter ON questions(chapter_id)',
    );

    await db.execute('CREATE INDEX idx_questions_test ON questions(test_id)');

    await db.execute(
      'CREATE INDEX idx_questions_passage ON questions(passage_id)',
    );

    await db.execute(
      'CREATE INDEX idx_tests_subject_grade_chapter ON tests(subject_id, grade, chapter_id)',
    );
  }
}
