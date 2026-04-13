import 'package:matricmate/data/database/database_service.dart';
import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SubjectDownloadService {
  final supabase = Supabase.instance.client;
  final DatabaseService _db = DatabaseService.instance;

  Future<void> downloadSubject(int subjectId) async {
    final db = await _db.database;

    /// CHAPTERS
    final chapters = await supabase
        .from('chapters')
        .select()
        .eq('subject_id', subjectId);

    for (final ch in chapters) {
      await db.insert(
        'chapters',
        ch,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    /// TESTS
    final tests = await supabase
        .from('tests')
        .select()
        .eq('subject_id', subjectId);

    for (final t in tests) {
      await db.insert('tests', t, conflictAlgorithm: ConflictAlgorithm.replace);
    }

    /// QUESTIONS (IMPORTANT — you were missing this)
    final questions = await supabase
        .from('questions')
        .select()
        .eq('subject_id', subjectId);

    for (final q in questions) {
      await db.insert(
        'questions',
        q,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }
}
