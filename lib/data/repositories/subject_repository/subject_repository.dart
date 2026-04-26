import 'package:matricmate/data/database/database_service.dart';
import 'package:matricmate/features/exam/models/question_model.dart';
import 'package:matricmate/features/exam/models/subject_model.dart';
import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SubjectRepository {
  final supabase = Supabase.instance.client;
  final DatabaseService _dbService = DatabaseService.instance;

  Future<void> downloadSubject(int subjectId) async {
    final db = await _dbService.database;

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
      final question = QuestionModel.fromMap(q);

      await db.insert(
        'questions',
        question.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  //get supabase subject
  Future<List<Map<String, dynamic>>> getSupabaseSubjects() async {
    try {
      return await supabase.from("subjects").select();
    } catch (e) {
      throw e.toString();
    }
  }

  // add singgle subject to local db
  Future<void> addSubject(SubjectMoModel subject) async {
    try {
      final db = await _dbService.database;
      await db.insert(
        'subjects',
        subject.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      e.toString();
    }
  }

  // update downloaded flag
  Future<void> updateIsDownloaded(String subject) async {
    try {
      final db = await _dbService.database;

      await db.update(
        'subjects',
        {'is_downloaded': 1},
        where: 'name = ?',
        whereArgs: [subject],
      );
    } catch (e) {
      e.toString();
    }
  }

  // local
  Future<List<Map<String, dynamic>>> getLocalSubjects() async {
    try {
      return await _dbService.getSubjects();
    } catch (e) {
      throw e.toString();
    }
  }
}
