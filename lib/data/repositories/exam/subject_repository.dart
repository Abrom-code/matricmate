import 'package:matricmate/data/database/database_service.dart';
import 'package:matricmate/features/exam/models/question_model.dart';
import 'package:matricmate/features/exam/models/subject_model.dart';
import 'package:matricmate/utils/exceptions/exeption_handler.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';
import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SubjectRepository {
  final supabase = Supabase.instance.client;
  final DatabaseService _dbService = DatabaseService.instance;
  Future<void> downloadSubject(int subjectId) async {
    try {
      final db = await _dbService.database;
      final batch = db.batch();

      // 1. Chapters
      final chapters = await supabase
          .from('chapters')
          .select()
          .eq('subject_id', subjectId);
      for (var ch in chapters)
        batch.insert(
          'chapters',
          ch,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

      // 2. Tests
      final tests = await supabase
          .from('tests')
          .select()
          .eq('subject_id', subjectId);
      for (var t in tests)
        batch.insert('tests', t, conflictAlgorithm: ConflictAlgorithm.replace);

      // 3. Questions & Collect Passage IDs
      final questionsData = await supabase
          .from('questions')
          .select()
          .eq('subject_id', subjectId);
      final Set<int> passageIds = {};
      final Set<String> imgUrls = {};

      for (var q in questionsData) {
        final question = QuestionModel.fromMap(q);
        if (question.passageId != null) passageIds.add(question.passageId!);
        if (question.imageUrl != null) {
          imgUrls.add(question.imageUrl!);
        }

        batch.insert(
          'questions',
          question.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      // 4. Passages (The missing piece)
      if (passageIds.isNotEmpty) {
        final passages = await supabase
            .from('passages')
            .select()
            .inFilter('id', passageIds.toList());
        for (var p in passages) {
          batch.insert(
            'passages',
            p,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }
      if (imgUrls.isNotEmpty) {
        await AppHelperFuntions.downloadImages(imgUrls);
      }

      await batch.commit(noResult: true);
    } catch (e) {
      throw AppExceptionHandler.handle(e);
    }
  }

  //get supabase subject
  Future<List<Map<String, dynamic>>> getSupabaseSubjects() async {
    try {
      return await supabase.from("subjects").select();
    } catch (e) {
      throw AppExceptionHandler.handle(e);
    }
  }

  Future<int> testNumbers(int id, String type) async {
    try {
      return await _dbService.getETestNumbers(id, type);
    } catch (e) {
      throw AppExceptionHandler.handle(e);
    }
  }

  Future<void> addSubject(SubjectMoModel subject) async {
    try {
      final db = await _dbService.database;

      await db.insert('subjects', {
        'id': subject.id,
        'name': subject.name,
        'is_natural': subject.isNatural ? 1 : 0,
        'is_common': subject.isCommon ? 1 : 0,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    } catch (e) {
      throw AppExceptionHandler.handle(e);
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
      throw AppExceptionHandler.handle(e);
    }
  }

  // local
  Future<List<Map<String, dynamic>>> getLocalSubjects() async {
    try {
      return await _dbService.getSubjects();
    } catch (e) {
      throw AppExceptionHandler.handle(e);
    }
  }
}
