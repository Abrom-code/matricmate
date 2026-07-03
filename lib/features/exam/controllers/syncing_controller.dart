import 'package:get/get.dart';
import 'package:matricmate/data/database/database_service.dart';
import 'package:matricmate/data/repositories/exam/subject_repository.dart';
import 'package:matricmate/data/repositories/exam/sync_repository.dart';
import 'package:matricmate/features/personalization/controller/user_controller.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';
import 'package:matricmate/utils/helpers/toast_helper.dart';
import 'package:matricmate/utils/network_manager/network_manager.dart';
import 'package:matricmate/features/exam/controllers/subjects_controller.dart';
import 'package:matricmate/features/exam/models/chapter_model.dart';
import 'package:matricmate/features/exam/models/question_model.dart';
import 'package:matricmate/features/exam/models/subject_model.dart';
import 'package:matricmate/features/exam/models/test_model.dart';
import 'package:matricmate/features/exam/models/passage_model.dart';
import 'package:sqflite/sqflite.dart';

class SyncingController extends GetxController {
  static SyncingController get instance => Get.find();

  final SubjectRepository _subjectRepo = SubjectRepository();
  final SyncRepository _syncRepository = SyncRepository();

  final refreshing = false.obs;

  Future<bool> syncAll() async {
    try {
      final isConnected = await NetworkManager.instance.isConnected();

      if (!isConnected) {
        ToastHelper.warning('No Internet!');
        return false;
      }

      refreshing.value = true;

      // Always sync subjects first — they should load for any user,
      // including free/inactive users and new signups.
      await syncSubjects();

      // Validate user session — but don't stop subject sync if this fails.
      final isValidUser = await UserController.instance.fetchUserRecord();

      final localSubjects = await _subjectRepo.getLocalSubjects();

      final downloadedIds = localSubjects
          .where((s) => s['is_downloaded'] == 1)
          .map((s) => s['id'].toString())
          .toList();

      final subjects = localSubjects.map((s) => s['id'] as int).toList();

      // Always download entrance/model tests (visible to all users).
      await _syncRepository.downloadEntranceTests(subjects);

      // Only sync downloaded chapter content if user is valid.
      if (isValidUser && downloadedIds.isNotEmpty) {
        await syncChapters(downloadedIds);
        await syncTests(downloadedIds);
        await syncQuestions(downloadedIds);
      }

      await SubjectsController.instance.syncSubjects();
      return true;
    } catch (e) {
      rethrow;
    } finally {
      refreshing.value = false;
    }
  }

  Future<void> syncSubjects() async {
    final localSubjects = await _subjectRepo.getLocalSubjects();
    final remoteData = await _subjectRepo.getSupabaseSubjects();

    final remote = (remoteData as List)
        .map((e) => SubjectModel.fromJson(e))
        .toList();

    for (final s in remote) {
      final local = localSubjects.firstWhereOrNull((sub) => sub['id'] == s.id);

      if (local == null) {
        final map = s.toMap();
        map['is_downloaded'] = 0;
        await _syncRepository.insertBatch('subjects', map);
      } else {
        await _syncRepository.updateBatch(s, local['is_downloaded'] ?? 0);
      }
    }

    final remoteIds = remote.map((e) => e.id).toSet();

    for (final local in localSubjects) {
      if (!remoteIds.contains(local['id'])) {
        await _syncRepository.deleteBatch(local);
      }
    }
    await _syncRepository.commitBatch();

    await SubjectsController.instance.loadLocalSubjects();
  }

  Future<void> syncChapters(List<String> subjectIds) async {
    final remoteData = await _syncRepository.getBySubjectId(
      'chapters',
      subjectIds,
    );

    final remote = (remoteData as List)
        .map((e) => ChapterModel.fromJson(e))
        .toList();

    if (remote.isEmpty) return;

    final db = await DatabaseService.instance.database;
    final batch = db.batch();
    for (final c in remote) {
      batch.insert(
        'chapters',
        c.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> syncTests(List<String> subjectIds) async {
    final remoteData = await _syncRepository.getBySubjectId(
      'tests',
      subjectIds,
    );

    final remote = (remoteData as List)
        .map((e) => TestModel.fromJson(e))
        .toList();

    if (remote.isEmpty) return;

    final db = await DatabaseService.instance.database;
    final batch = db.batch();
    for (final t in remote) {
      batch.insert(
        'tests',
        SyncRepository.sanitizeTest(t.toMap()),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> syncQuestions(List<String> subjectIds) async {
    final remoteData = await _syncRepository.getBySubjectId(
      'questions',
      subjectIds,
    );

    final remote = (remoteData as List)
        .map((e) => QuestionModel.fromJson(e))
        .toList();

    if (remote.isEmpty) return;

    final db = await DatabaseService.instance.database;
    final batch = db.batch();

    final Set<String> imageUrls = {};
    final Set<int> passageIds = {};

    for (final q in remote) {
      batch.insert(
        'questions',
        q.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      if (q.passageId != null) passageIds.add(q.passageId!);
      if (q.imageUrl != null && q.imageUrl!.isNotEmpty) {
        imageUrls.add(q.imageUrl!);
      }
    }

    await batch.commit(noResult: true);

    if (passageIds.isNotEmpty) await syncPassages(passageIds.toList());
    if (imageUrls.isNotEmpty) {
      await AppHelperFunctions.downloadImages(imageUrls);
    }
  }

  Future<void> syncPassages(List<int> passageIds) async {
    final remoteData = await _syncRepository.getPassages(passageIds);

    final remote = (remoteData as List)
        .map((e) => PassageModel.fromMap(e))
        .toList();

    if (remote.isEmpty) return;

    final db = await DatabaseService.instance.database;
    final batch = db.batch();
    for (final p in remote) {
      batch.insert(
        'passages',
        SyncRepository.sanitizePassage(p.toMap()),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }
}
