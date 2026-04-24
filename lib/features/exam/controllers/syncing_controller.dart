import 'dart:convert';
import 'package:get/get.dart';
import 'package:matricmate/features/personalization/controller/user_controller.dart';
import 'package:matricmate/utils/helpers/toast_helper.dart';
import 'package:matricmate/utils/network_manager/network_manager.dart';
import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:matricmate/data/database/database_service.dart';
import 'package:matricmate/features/exam/controllers/subjects_controller.dart';
import 'package:matricmate/features/exam/models/chapter_model.dart';
import 'package:matricmate/features/exam/models/question_model.dart';
import 'package:matricmate/features/exam/models/subject_model.dart';
import 'package:matricmate/features/exam/models/test_model.dart';
import 'package:matricmate/features/exam/models/passage_model.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

class SyncingController extends GetxController {
  static SyncingController get instance => Get.find();

  final SupabaseClient supabase = Supabase.instance.client;
  final DatabaseService _databaseService = DatabaseService.instance;
  final refreshing = false.obs;

  Future<void> syncAll() async {
    try {
      final isConnectd = await NetworkManager.instance.hasRealInternet();
      if (!isConnectd) {
        ToastHelper.warning(
          "No Internet!",
          "Please turn on mobile data or connect to WIFI!",
        );
        return;
      }
      refreshing.value = true;

      await syncSubjects();
      await UserController.instance.fetchUserRecord();

      final localSubjects = await _databaseService.getSubjects();
      final downloadedIds = localSubjects
          .where((s) => s['is_downloaded'] == 1)
          .map((s) => s['id'].toString())
          .toList();

      if (downloadedIds.isNotEmpty) {
        await syncChapters(downloadedIds);
        await syncTests(downloadedIds);
        await syncQuestions(downloadedIds);
      }
      ToastHelper.success("Success", "All Subjects are refreshed");
    } on Exception {
      ToastHelper.error("Faild", "Faild to refresh!");
    } finally {
      refreshing.value = false;
    }
  }

  //  SYNC SUBJECTS
  Future<void> syncSubjects() async {
    try {
      final localSubjects = await _databaseService.getSubjects();
      final remoteData = await supabase.from("subjects").select();
      final remote = (remoteData as List)
          .map((e) => SubjectMoModel.fromJson(e))
          .toList();

      final db = await _databaseService.database;
      final batch = db.batch();

      for (final s in remote) {
        final local = localSubjects.firstWhereOrNull(
          (sub) => sub['id'] == s.id,
        );

        if (local == null) {
          batch.insert('subjects', s.toMap());
        } else {
          batch.update(
            'subjects',
            {...s.toMap(), 'is_downloaded': local['is_downloaded']},
            where: 'id = ?',
            whereArgs: [s.id],
          );
        }
      }

      final remoteIds = remote.map((e) => e.id).toSet();
      for (final local in localSubjects) {
        if (!remoteIds.contains(local['id'])) {
          batch.delete('subjects', where: 'id = ?', whereArgs: [local['id']]);
        }
      }

      await batch.commit(noResult: true);
      SubjectsController.instance.loadSubjects();
    } catch (e) {
      AppHelperFuntions.showAlert("Subject Sync", e.toString());
    }
  }

  //  SYNC CHAPTERS
  Future<void> syncChapters(List<String> subjectIds) async {
    try {
      final remoteData = await supabase
          .from('chapters')
          .select()
          .inFilter('subject_id', subjectIds);
      final remote = (remoteData as List)
          .map((rc) => ChapterModel.fromJson(rc))
          .toList();

      final db = await _databaseService.database;
      final batch = db.batch();
      for (final c in remote) {
        batch.insert(
          'chapters',
          c.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    } catch (e) {
      AppHelperFuntions.showAlert("Chapter Sync", e.toString());
    }
  }

  //  SYNC TESTS
  Future<void> syncTests(List<String> subjectIds) async {
    try {
      final remoteData = await supabase
          .from('tests')
          .select()
          .inFilter('subject_id', subjectIds);
      final remote = (remoteData as List)
          .map((rc) => TestModel.fromJson(rc))
          .toList();

      final db = await _databaseService.database;
      final batch = db.batch();
      for (final t in remote) {
        batch.insert(
          'tests',
          t.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    } catch (e) {
      AppHelperFuntions.showAlert("Test Sync", e.toString());
    }
  }

  //  SYNC QUESTIONS & PASSAGES
  Future<void> syncQuestions(List<String> subjectIds) async {
    try {
      final remoteData = await supabase
          .from('questions')
          .select()
          .inFilter('subject_id', subjectIds);
      final remote = (remoteData as List)
          .map((rc) => QuestionModel.fromJson(rc))
          .toList();

      final db = await _databaseService.database;
      final batch = db.batch();
      final List<int> passageIds = [];

      for (final q in remote) {
        final questionMap = q.toMap();
        questionMap['options'] = jsonEncode(q.options);

        batch.insert(
          'questions',
          questionMap,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );

        if (q.passageId != null) {
          passageIds.add(q.passageId!);
        }
      }

      await batch.commit(noResult: true);

      // Sync Passages referenced by these questions
      if (passageIds.isNotEmpty) {
        await syncPassages(passageIds.toSet().toList());
      }
    } catch (e) {
      AppHelperFuntions.showAlert("Questions Sync", e.toString());
    }
  }

  //  SYNC PASSAGES
  Future<void> syncPassages(List<int> passageIds) async {
    try {
      final remoteData = await supabase
          .from('passages')
          .select()
          .inFilter('id', passageIds);

      final remote = (remoteData as List)
          .map((p) => PassageModel.fromJson(p))
          .toList();

      final db = await _databaseService.database;
      final batch = db.batch();
      for (final p in remote) {
        batch.insert(
          'passages',
          p.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    } catch (e) {
      AppHelperFuntions.showAlert("Passage Sync", e.toString());
    }
  }
}
