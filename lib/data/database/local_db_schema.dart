import 'package:sqflite/sqflite.dart';

class DBschema {
  static Future<void> create(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');

    await db.execute('''
      CREATE TABLE subjects (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
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
      CREATE TABLE tests (
        id INTEGER PRIMARY KEY,
        subject_id INTEGER NOT NULL,
        grade INTEGER,
        chapter_id INTEGER,
        title TEXT NOT NULL,
        question_count INTEGER NOT NULL,
        type TEXT NOT NULL DEFAULT 'fixed',
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
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
        passage_id INTEGER,
        question_text TEXT NOT NULL,
        image_url TEXT,
        options TEXT NOT NULL,
        correct_option_index INTEGER NOT NULL,
        explanation_en TEXT,
        explanation_am TEXT,
        question_order INTEGER DEFAULT 1,
        FOREIGN KEY(subject_id) REFERENCES subjects(id) ON DELETE CASCADE,
        FOREIGN KEY(chapter_id) REFERENCES chapters(id) ON DELETE SET NULL
      );
    ''');

    await db.execute('''
      CREATE TABLE test_questions (
        test_id INTEGER NOT NULL,
        question_id INTEGER NOT NULL,
        position INTEGER,
        PRIMARY KEY (test_id, question_id),
        FOREIGN KEY(test_id) REFERENCES tests(id) ON DELETE CASCADE,
        FOREIGN KEY(question_id) REFERENCES questions(id) ON DELETE CASCADE
      );
    ''');

    await db.execute('''
      CREATE TABLE test_progress (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        test_id INTEGER NOT NULL,
        questions_attempted INTEGER DEFAULT 0,
        correct_answers INTEGER DEFAULT 0,
        total_questions INTEGER NOT NULL,
        status TEXT DEFAULT 'not_started',
        last_question_id INTEGER,
        started_at TEXT,
        updated_at TEXT,
        completed_at TEXT,
        FOREIGN KEY(test_id) REFERENCES tests(id) ON DELETE CASCADE
      );
    ''');

    await db.execute('''
        CREATE TABLE question_answers (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          test_progress_id INTEGER NOT NULL,
          question_id INTEGER NOT NULL,
          selected_option_index INTEGER,
          is_correct INTEGER,
          answered_at TEXT,
          FOREIGN KEY(test_progress_id) REFERENCES test_progress(id) ON DELETE CASCADE,
          FOREIGN KEY(question_id) REFERENCES questions(id) ON DELETE CASCADE
      );
    ''');

    // INDEXES
    await db.execute(
      'CREATE INDEX idx_questions_subject_grade ON questions(subject_id, grade)',
    );
    await db.execute(
      'CREATE INDEX idx_questions_chapter ON questions(chapter_id)',
    );
    await db.execute('CREATE INDEX idx_tests_subject ON tests(subject_id)');
    await db.execute(
      'CREATE INDEX idx_test_questions_test ON test_questions(test_id)',
    );
    await db.execute(
      'CREATE INDEX idx_test_questions_question ON test_questions(question_id)',
    );
    await db.execute(
      'CREATE INDEX idx_test_progress_test ON test_progress(test_id)',
    );
    await db.execute(
      'CREATE INDEX idx_question_answers_progress ON question_answers(test_progress_id)',
    );
  }
}
