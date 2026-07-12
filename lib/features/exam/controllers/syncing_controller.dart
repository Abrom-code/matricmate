import 'package:get/get.dart';
import 'package:matricmate/data/database/database_service.dart';
import 'package:matricmate/data/repositories/exam/subject_repository.dart';
import 'package:matricmate/data/repositories/exam/sync_repository.dart';
import 'package:matricmate/features/exam/controllers/subjects_controller.dart';
import 'package:matricmate/features/exam/models/chapter_model.dart';
import 'package:matricmate/features/exam/models/passage_model.dart';
import 'package:matricmate/features/exam/models/question_model.dart';
import 'package:matricmate/features/exam/models/subject_model.dart';
import 'package:matricmate/features/exam/models/test_model.dart';
import 'package:matricmate/features/personalization/controller/user_controller.dart';
import 'package:matricmate/utils/exceptions/exeption_handler.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';
import 'package:matricmate/utils/helpers/toast_helper.dart';
import 'package:matricmate/utils/local_storage/sync_prefs.dart';
import 'package:matricmate/utils/network_manager/network_manager.dart';
import 'package:sqflite/sqflite.dart';

class SyncingController extends GetxController {
  static SyncingController get instance => Get.find();

  final SubjectRepository _subjectRepo = SubjectRepository();
  final SyncRepository _syncRepository = SyncRepository();

  final refreshing = false.obs;
  final entranceSyncing = false.obs;

  // ── Entrance-only sync (from entrance screen button) ─────────────────────

  Future<void> syncEntranceExams() async {
    try {
      final isConnected = await NetworkManager.instance.isConnected();
      if (!isConnected) {
        ToastHelper.warning('No Internet!');
        return;
      }

      // Don't run while a per-subject entrance download is already in progress
      // — they both write to the same tables and would conflict.
      if (SubjectsController.instance.entranceDownloadStep.isNotEmpty) {
        ToastHelper.warning('A download is already in progress. Please wait.');
        return;
      }

      entranceSyncing.value = true;

      final localSubjects = await _subjectRepo.getLocalSubjects();

      // Only refresh subjects the user has explicitly downloaded.
      // Passing all subject IDs here would re-download entrance content
      // for subjects the user never asked for.
      final subjectIds = localSubjects
          .where((s) => s['is_entrance_downloaded'] == 1)
          .map((s) => s['id'] as int)
          .toList();

      if (subjectIds.isEmpty) {
        ToastHelper.warning('No entrance exams downloaded yet. Download a subject first.');
        return;
      }

      // Capture timestamp BEFORE the network call to avoid missing rows
      // written in the window between fetch-start and fetch-end.
      final syncStarted = DateTime.now().toUtc();
      final since = await SyncPrefs.lastEntranceSync();

      await _syncRepository.downloadEntranceTests(subjectIds, since: since);

      // Mark every subject that now has entrance tests in the local DB as
      // entrance-downloaded (the bulk sync writes the rows but never sets the flag).
      final db = await DatabaseService.instance.database;
      final entranceSubjectRows = await db.rawQuery(
        'SELECT DISTINCT subject_id FROM tests WHERE subject_id IN (${subjectIds.map((_) => '?').join(',')}) AND type IN (\'entrance\', \'model\')',
        subjectIds,
      );
      for (final row in entranceSubjectRows) {
        await db.update(
          'subjects',
          {'is_entrance_downloaded': 1},
          where: 'id = ?',
          whereArgs: [row['subject_id']],
        );
      }

      await SyncPrefs.saveEntranceSync(syncStarted);

      // Reload subjects (updates is_entrance_downloaded flags) then force-reload
      // test counts from local SQLite — this bypasses the "needsRemote" guard in
      // loadTestNumbers so newly synced tests are reflected immediately.
      final dbSubjects = await _subjectRepo.getLocalSubjects();
      SubjectsController.instance.subjects.assignAll(
        dbSubjects.map((e) => SubjectModel.fromMap(e)).toList(),
      );
      await SubjectsController.instance.reloadTestNumbersFromLocal();

      ToastHelper.success(since == null ? 'Entrance exams loaded!' : 'Entrance exams updated!');
    } catch (e) {
      AppExceptionHandler.handleResponse(e);
    } finally {
      entranceSyncing.value = false;
    }
  }

  // ── Full sync (from home screen button) ──────────────────────────────────

  Future<bool> syncAll() async {
    try {
      final isConnected = await NetworkManager.instance.isConnected();
      if (!isConnected) {
        ToastHelper.warning('No Internet!');
        return false;
      }

      refreshing.value = true;

      // Capture all timestamps BEFORE any network call
      final syncStarted = DateTime.now().toUtc();
      final results = await Future.wait([
        SyncPrefs.lastSubjectsSync(),
        SyncPrefs.lastEntranceSync(),
        SyncPrefs.lastChaptersSync(),
        UserController.instance.fetchUserRecord(),
      ]);

      final sinceSubjects = results[0] as DateTime?;
      final sinceEntrance = results[1] as DateTime?;
      final sinceChapters = results[2] as DateTime?;
      final isValidUser   = results[3] as bool;

      // Sync subjects (delta)
      await syncSubjects(since: sinceSubjects);
      await SyncPrefs.saveSubjectsSync(syncStarted);

      final localSubjects = await _subjectRepo.getLocalSubjects();
      final downloadedIds = localSubjects
          .where((s) => s['is_downloaded'] == 1)
          .map((s) => s['id'].toString())
          .toList();

      // Only sync entrance/model tests for subjects the user explicitly
      // downloaded — not all subjects. This prevents re-downloading
      // entrance content for subjects the user hasn't asked for.
      final entranceDownloadedIds = localSubjects
          .where((s) => s['is_entrance_downloaded'] == 1)
          .map((s) => s['id'] as int)
          .toList();

      if (isValidUser && downloadedIds.isNotEmpty) {
        final futures = <Future>[_syncChapterContent(downloadedIds, since: sinceChapters)];
        if (entranceDownloadedIds.isNotEmpty) {
          futures.add(_syncRepository.downloadEntranceTests(
              entranceDownloadedIds, since: sinceEntrance));
        }
        await Future.wait(futures);
        await SyncPrefs.saveChaptersSync(syncStarted);
      } else if (entranceDownloadedIds.isNotEmpty) {
        await _syncRepository.downloadEntranceTests(
            entranceDownloadedIds, since: sinceEntrance);
      }

      if (entranceDownloadedIds.isNotEmpty) {
        await SyncPrefs.saveEntranceSync(syncStarted);
      }
      // Reload local subjects to reflect any changes written by syncSubjects()
      await SubjectsController.instance.loadLocalSubjects();
      return true;
    } catch (e) {
      rethrow;
    } finally {
      refreshing.value = false;
    }
  }

  // ── Chapter content delta sync ────────────────────────────────────────────

  Future<void> _syncChapterContent(
    List<String> downloadedIds, {
    DateTime? since,
  }) async {
    // On first sync: fetch chapters too. On delta: chapters rarely change,
    // but we still check so new chapters added to a subject are picked up.
    final fetchChapters = since == null;

    final futures = <Future>[
      // Only sync chapter/grade tests — entrance & model are handled separately
      _syncRepository.getBySubjectId(
        'tests', downloadedIds,
        since: since,
        typeFilter: ['chapter', 'grade'],
      ),
      _syncRepository.getBySubjectId('questions', downloadedIds, since: since),
    ];
    if (fetchChapters) {
      futures.add(_syncRepository.getBySubjectId('chapters', downloadedIds));
    }

    final fetched = await Future.wait(futures);

    final tests = (fetched[0] as List).map((e) => TestModel.fromJson(e)).toList();
    final rawQuestions = fetched[1] as List;
    final chapters = fetchChapters
        ? (fetched[2] as List).map((e) => ChapterModel.fromJson(e)).toList()
        : <ChapterModel>[];

    // If nothing changed, bail early
    if (tests.isEmpty && rawQuestions.isEmpty && chapters.isEmpty) return;

    final Set<int> passageIds = {};
    final Set<String> imageUrls = {};
    final questions = rawQuestions.map((q) {
      final model = QuestionModel.fromJson(q);
      if (model.passageId != null) passageIds.add(model.passageId!);
      if (model.imageUrl != null && model.imageUrl!.isNotEmpty) {
        imageUrls.add(model.imageUrl!);
      }
      if (model.explanationImageUrl != null && model.explanationImageUrl!.isNotEmpty) {
        imageUrls.add(model.explanationImageUrl!);
      }
      return model;
    }).toList();

    // Fetch only passages that are new or changed
    final passageFuture = passageIds.isNotEmpty
        ? syncPassages(passageIds.toList())
        : Future.value();

    final db = await DatabaseService.instance.database;
    final batch = db.batch();

    for (final c in chapters) {
      batch.insert('chapters', c.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    for (final t in tests) {
      batch.insert('tests', SyncRepository.sanitizeTest(t.toMap()),
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    for (final q in questions) {
      batch.insert('questions', q.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    }

    await Future.wait([
      batch.commit(noResult: true),
      passageFuture,
      if (imageUrls.isNotEmpty) AppHelperFunctions.downloadImages(imageUrls),
    ]);
  }

  // ── Subject sync (delta when updated_at is available) ────────────────────

  Future<void> syncSubjects({DateTime? since}) async {
    final localSubjects = await _subjectRepo.getLocalSubjects();
    final remoteData = await _subjectRepo.getSupabaseSubjects(since: since);

    final remote = (remoteData as List)
        .map((e) => SubjectModel.fromJson(e))
        .toList();

    // On delta sync, remote only contains changed rows — skip delete check.
    // On full sync (since == null), also remove subjects deleted from remote.
    if (since == null) {
      final remoteIds = remote.map((e) => e.id).toSet();
      for (final local in localSubjects) {
        if (!remoteIds.contains(local['id'])) {
          await _syncRepository.deleteBatch(local);
        }
      }
    }

    for (final s in remote) {
      final local = localSubjects.firstWhereOrNull((sub) => sub['id'] == s.id);
      if (local == null) {
        final map = s.toMap();
        map['is_downloaded'] = 0;
        map['is_entrance_downloaded'] = 0;
        await _syncRepository.insertBatch('subjects', map);
      } else {
        await _syncRepository.updateBatch(
          s,
          local['is_downloaded'] ?? 0,
          localEntranceDownloaded: local['is_entrance_downloaded'] ?? 0,
        );
      }
    }

    await _syncRepository.commitBatch();
    await SubjectsController.instance.loadLocalSubjects();
  }

  // ── Passages (fetched by ID — no subject filter available) ───────────────

  Future<void> syncPassages(List<int> passageIds) async {
    final remoteData = await _syncRepository.getPassages(passageIds);

    final remote = (remoteData as List)
        .map((e) => PassageModel.fromMap(e))
        .toList();

    if (remote.isEmpty) return;

    final db = await DatabaseService.instance.database;
    final batch = db.batch();
    for (final p in remote) {
      batch.insert('passages', SyncRepository.sanitizePassage(p.toMap()),
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  /// Call this on sign-out so the next login does a full sync.
  Future<void> clearSyncTimestamps() => SyncPrefs.clearAll();
}
