import 'dart:async';

import 'package:get/get.dart';
import 'package:matricmate/data/database/database_service.dart';
import 'package:matricmate/data/repositories/exam/subject_repository.dart';
import 'package:matricmate/data/repositories/exam/sync_repository.dart';
import 'package:matricmate/features/exam/controllers/syncing_controller.dart';
import 'package:matricmate/features/exam/models/result_model.dart';
import 'package:matricmate/features/exam/models/subject_model.dart';
import 'package:matricmate/features/personalization/controllers/user_controller.dart';
import 'package:matricmate/utils/exceptions/exeption_handler.dart';
import 'package:matricmate/utils/helpers/toast_helper.dart';
import 'package:matricmate/utils/network_manager/network_manager.dart';

class SubjectsController extends GetxController {
  static SubjectsController get instance => Get.find();

  final SubjectRepository _repo = SubjectRepository();

  final RxBool isLoading = false.obs;
  final RxMap<String, bool> downloadingMap = <String, bool>{}.obs;

  // Subject download progress: subjectName → {step, progress}
  final RxMap<String, String> subjectDownloadStep = <String, String>{}.obs;
  final RxMap<String, double> subjectDownloadProgress = <String, double>{}.obs;

  // Entrance download progress: subjectId → {step, progress}
  final RxMap<int, String> entranceDownloadStep = <int, String>{}.obs;
  final RxMap<int, double> entranceDownloadProgress = <int, double>{}.obs;

  final RxList<SubjectModel> subjects = <SubjectModel>[].obs;
  final RxMap<int, int> entranceTestNumbers = <int, int>{}.obs;
  final RxMap<int, int> modelTestNumbers = <int, int>{}.obs;

  final RxString selectedStream = UserController.instance.user.value.stream.obs;

  // ── Resume banner ─────────────────────────────────────────────────────────
  /// The most recent in-progress draft, or null if none exists.
  final Rxn<ResultModel> inProgressDraft = Rxn<ResultModel>();
  /// Test title for the in-progress draft.
  final RxString inProgressTestTitle = ''.obs;
  /// Test time (minutes) for the in-progress draft.
  final RxInt inProgressTestTime = 0.obs;

  // ── Entrance resume banner ─────────────────────────────────────────────────
  /// The most recent in-progress entrance/model exam draft, or null if none.
  final Rxn<ResultModel> inProgressEntranceDraft = Rxn<ResultModel>();
  final RxString inProgressEntranceTitle = ''.obs;
  final RxInt inProgressEntranceTime = 0.obs;

  @override
  void onInit() {
    // Don't call loadLocalSubjects() here — AuthenticationController._init()
    // calls it before navigating, so data is already loaded by the time
    // any screen using this controller is built.
    ever(UserController.instance.user, (user) {
      selectedStream.value = user.stream;
    });

    super.onInit();
  }

  /// Loads the most recent in-progress test draft and populates banner fields.
  Future<void> loadInProgressBanner() async {
    try {
      final row = await DatabaseService.instance.loadMostRecentInProgressResult();
      if (row == null) {
        inProgressDraft.value = null;
        inProgressTestTitle.value = '';
        return;
      }
      inProgressDraft.value = ResultModel.fromMap(row);
      inProgressTestTitle.value = row['test_title'] as String? ?? '';
      inProgressTestTime.value = row['test_time'] as int? ?? -1;
    } catch (_) {
      inProgressDraft.value = null;
    }
  }

  /// Loads the most recent in-progress entrance/model exam draft.
  Future<void> loadInProgressEntranceBanner() async {
    try {
      final row = await DatabaseService.instance.loadMostRecentInProgressResult(
        types: ['entrance', 'model'],
      );
      if (row == null) {
        inProgressEntranceDraft.value = null;
        inProgressEntranceTitle.value = '';
        return;
      }
      inProgressEntranceDraft.value = ResultModel.fromMap(row);
      inProgressEntranceTitle.value = row['test_title'] as String? ?? '';
      inProgressEntranceTime.value = row['test_time'] as int? ?? -1;
    } catch (_) {
      inProgressEntranceDraft.value = null;
    }
  }

  /// LOCAL ONLY (startup)
  Future<void> loadLocalSubjects() async {
    try {
      isLoading.value = true;

      final dbSubjects = await _repo.getLocalSubjects();

      subjects.assignAll(
        dbSubjects.map((e) => SubjectModel.fromMap(e)).toList(),
      );
      // loadTestNumbers reads persisted entrance_count/model_count from the
      // subjects table — no network call needed on restart.
      await loadTestNumbers(subjects);
    } finally {
      isLoading.value = false;
    }
  }

  /// Called on first launch when local DB is empty.
  /// Fetches subjects from remote + their entrance counts, then returns.
  /// This is the only awaited network call during startup.
  Future<void> initFromRemote() async {
    try {
      isLoading.value = true;

      // Fetch subjects and save to local DB
      await SyncingController.instance.syncSubjects();

      // Now load from local (just written) + fetch entrance counts (awaited)
      final dbSubjects = await _repo.getLocalSubjects();
      subjects.assignAll(
        dbSubjects.map((e) => SubjectModel.fromMap(e)).toList(),
      );

      if (subjects.isNotEmpty) {
        // Load local counts (all 0 at this point for a first-run user)
        await Future.wait(
          subjects.map((s) async {
            entranceTestNumbers[s.id] = await _repo.testNumbers(s.id, 'entrance');
            modelTestNumbers[s.id] = await _repo.testNumbers(s.id, 'model');
          }),
        );
        // Remote counts are fetched by the caller (_runInitThenNavigate)
        // via refreshEntranceCountsFromRemote — no need to duplicate here.
      }
    } catch (_) {
      // Non-fatal
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> syncAll() async {
    try {
      final finished = await SyncingController.instance.syncAll();
      if (finished) {
        ToastHelper.success('All subjects synced successfully!');
      }
    } catch (e) {
      AppExceptionHandler.handleResponse(e);
    }
  }

  /// DOWNLOAD SUBJECT (chapter content)
  Future<void> downloadSubject(String subject, int subjectId) async {
    try {
      final isConnected = await NetworkManager.instance.isConnected();
      if (!isConnected) {
        ToastHelper.warning('No Internet!');
        return;
      }

      subjectDownloadStep[subject] = 'Starting…';
      subjectDownloadProgress[subject] = 0.0;
      downloadingMap[subject] = true;

      await _repo.downloadSubject(
        subjectId,
        onStep: (step, progress) {
          subjectDownloadStep[subject] = step;
          subjectDownloadProgress[subject] = progress;
        },
      );

      await _repo.updateIsDownloaded(subject);
      await loadLocalSubjects();
      ToastHelper.success('$subject downloaded successfully');
    } catch (e) {
      AppExceptionHandler.handleResponse(e);
    } finally {
      subjectDownloadStep.remove(subject);
      subjectDownloadProgress.remove(subject);
      downloadingMap[subject] = false;
    }
  }

  /// DOWNLOAD ENTRANCE + MODEL EXAMS for one subject
  Future<void> downloadEntranceExams(SubjectModel subject) async {
    try {
      final isConnected = await NetworkManager.instance.isConnected();
      if (!isConnected) {
        ToastHelper.warning('No Internet!');
        return;
      }

      final syncRepo = SyncRepository();
      entranceDownloadStep[subject.id] = 'Starting…';
      entranceDownloadProgress[subject.id] = 0.0;

      await syncRepo.downloadEntranceForSubject(
        subject.id,
        onStep: (step, progress) {
          entranceDownloadStep[subject.id] = step;
          entranceDownloadProgress[subject.id] = progress;
        },
      );

      await _repo.updateIsEntranceDownloaded(subject.id);
      await loadLocalSubjects();
      ToastHelper.success('${subject.name} exams downloaded!');
    } catch (e) {
      AppExceptionHandler.handleResponse(e);
    } finally {
      entranceDownloadStep.remove(subject.id);
      entranceDownloadProgress.remove(subject.id);
    }
  }

  /// Fetches entrance/model counts from Supabase, updates in-memory maps,
  /// and persists the counts to SQLite so they survive app restarts.
  Future<void> refreshEntranceCountsFromRemote() async {
    try {
      final current = subjects.toList();
      if (current.isEmpty) return;

      final isConnected = await NetworkManager.instance.isConnected();
      if (!isConnected) return;

      final subjectIds = current.map((s) => s.id).toList();
      final remoteCounts = await _repo.remoteEntranceTestCounts(subjectIds);
      if (remoteCounts.isEmpty) return;

      final db = await DatabaseService.instance.database;

      for (final entry in remoteCounts.entries) {
        final sid = entry.key;
        final remoteEntrance = entry.value['entrance'] ?? 0;
        final remoteModel = entry.value['model'] ?? 0;
        // Take whichever is higher — preserves locally-downloaded counts
        // if the remote query returns a lower number for any reason.
        final newEntrance =
            remoteEntrance > (entranceTestNumbers[sid] ?? 0)
                ? remoteEntrance
                : (entranceTestNumbers[sid] ?? 0);
        final newModel =
            remoteModel > (modelTestNumbers[sid] ?? 0)
                ? remoteModel
                : (modelTestNumbers[sid] ?? 0);

        entranceTestNumbers[sid] = newEntrance;
        modelTestNumbers[sid] = newModel;

        // Persist so counts are available on restart without a network call
        await db.update(
          'subjects',
          {'entrance_count': newEntrance, 'model_count': newModel},
          where: 'id = ?',
          whereArgs: [sid],
        );
      }
    } catch (_) {
      // Non-fatal — best-effort
    }
  }

  Future<void> loadTestNumbers(List<SubjectModel> subjects) async {
    try {
      // Read persisted counts from subjects table.
      // entrance_count/model_count are written by refreshEntranceCountsFromRemote
      // and survive restarts — no network needed here.
      for (final s in subjects) {
        entranceTestNumbers[s.id] = s.entranceCount;
        modelTestNumbers[s.id] = s.modelCount;
      }

      // If ANY subject has 0 for both counts (never fetched or new subject
      // added), fetch from remote in the background for all zero subjects.
      final zeroSubjects = subjects
          .where((s) =>
              (entranceTestNumbers[s.id] ?? 0) == 0 &&
              (modelTestNumbers[s.id] ?? 0) == 0)
          .toList();
      if (zeroSubjects.isNotEmpty) {
        unawaited(_fetchRemoteCountsIfNeeded(zeroSubjects));
      }
    } catch (e) {
      AppExceptionHandler.handleResponse(e);
    }
  }

  /// Reloads entrance/model test counts from persisted subject columns.
  Future<void> reloadTestNumbersFromLocal() async {
    try {
      final dbSubjects = await _repo.getLocalSubjects();
      for (final row in dbSubjects) {
        final sid = row['id'] as int;
        entranceTestNumbers[sid] = row['entrance_count'] as int? ?? 0;
        modelTestNumbers[sid] = row['model_count'] as int? ?? 0;
      }
    } catch (e) {
      AppExceptionHandler.handleResponse(e);
    }
  }

  Future<void> _fetchRemoteCountsIfNeeded(List<SubjectModel> subjects) async {
    try {
      final isConnected = await NetworkManager.instance.isConnected();
      if (!isConnected) return;

      final subjectIds = subjects.map((s) => s.id).toList();
      final remoteCounts = await _repo.remoteEntranceTestCounts(subjectIds);
      if (remoteCounts.isEmpty) return;

      final db = await DatabaseService.instance.database;

      for (final entry in remoteCounts.entries) {
        final sid = entry.key;
        // Only fill if still 0 — don't overwrite values already set
        final entrance = entry.value['entrance'] ?? 0;
        final model = entry.value['model'] ?? 0;
        if ((entranceTestNumbers[sid] ?? 0) == 0) {
          entranceTestNumbers[sid] = entrance;
        }
        if ((modelTestNumbers[sid] ?? 0) == 0) {
          modelTestNumbers[sid] = model;
        }
        // Persist both values so the next restart reads from SQLite
        await db.update(
          'subjects',
          {
            'entrance_count': entranceTestNumbers[sid],
            'model_count': modelTestNumbers[sid],
          },
          where: 'id = ?',
          whereArgs: [sid],
        );
      }
    } catch (_) {
      // Silent — best-effort
    }
  }

  List<SubjectModel> get filteredSubjects {
    final isNatural = selectedStream.value == 'natural';

    return subjects.where((subject) {
      return subject.isCommon || subject.isNatural == isNatural;
    }).toList();
  }
}
