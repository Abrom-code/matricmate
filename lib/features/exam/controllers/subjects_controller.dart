import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';
import 'package:matricmate/data/database/database_service.dart';
import 'package:matricmate/data/repositories/exam/subject_repository.dart';
import 'package:matricmate/data/repositories/exam/sync_repository.dart';
import 'package:matricmate/features/exam/controllers/syncing_controller.dart';
import 'package:matricmate/features/exam/models/paused_test_info.dart';
import 'package:matricmate/features/exam/models/subject_model.dart';
import 'package:matricmate/features/personalization/controllers/user_controller.dart';
import 'package:matricmate/utils/exceptions/exception_handler.dart';
import 'package:matricmate/utils/helpers/toast_helper.dart';
import 'package:matricmate/utils/network_manager/network_manager.dart';

class SubjectsController extends GetxController {
  static SubjectsController get instance => Get.find();

  final SubjectRepository _repo = SubjectRepository();

  final RxBool isLoading = false.obs;

  /// True when the last load attempt found no usable connection.
  /// Drives the offline variant of the home-screen empty state.
  final RxBool isOffline = false.obs;

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

  final RxList<PausedTestInfoModel> pausedTests = <PausedTestInfoModel>[].obs;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

  /// In-flight [ensureSubjectsLoaded] call, used to dedupe concurrent runs.
  /// SyncRepository keeps a single shared batch that is not reentrant, so two
  /// overlapping syncs would corrupt it.
  Future<void>? _ensureInFlight;

  @override
  void onInit() {
    // Data is preloaded by AuthenticationController._init()
    ever(UserController.instance.user, (user) {
      selectedStream.value = user.stream;
    });

    // Auto-retry: if we came up with nothing cached (e.g. first login while
    // offline), load subjects as soon as a connection appears.
    _connectivitySub = Connectivity().onConnectivityChanged.listen((result) {
      final hasInterface = !result.contains(ConnectivityResult.none);
      if (hasInterface && subjects.isEmpty) {
        unawaited(ensureSubjectsLoaded());
      }
    });

    super.onInit();
  }

  @override
  void onClose() {
    _connectivitySub?.cancel();
    super.onClose();
  }

  /// Single entry point for getting subjects on screen.
  ///
  /// Loads the local cache first so the grid paints immediately, then tops up
  /// from Supabase when online. Never throws — startup must not be blocked by
  /// a network failure.
  ///
  /// [forceRemote] re-fetches from Supabase even when subjects are already
  /// cached (used by the empty-state retry button).
  Future<void> ensureSubjectsLoaded({bool forceRemote = false}) async {
    // Coalesce concurrent calls (startup + connectivity listener + retry tap).
    final inFlight = _ensureInFlight;
    if (inFlight != null) return inFlight;

    final run = _ensureSubjectsLoaded(forceRemote: forceRemote);
    _ensureInFlight = run;
    try {
      await run;
    } finally {
      _ensureInFlight = null;
    }
  }

  Future<void> _ensureSubjectsLoaded({required bool forceRemote}) async {
    try {
      // Keep the stream filter in step with the current user. selectedStream is
      // captured at construction, which for a fresh signup is still ''.
      final currentStream = UserController.instance.user.value.stream;
      if (currentStream.isNotEmpty && selectedStream.value != currentStream) {
        selectedStream.value = currentStream;
      }

      // 1. Paint from cache.
      await loadLocalSubjects();

      // 2. Subjects are public content — never gate this on the user record.
      final isConnected = await NetworkManager.instance.isConnected();
      if (!isConnected) {
        isOffline.value = true;
        return;
      }
      isOffline.value = false;

      // 3. Top up from remote when the cache is empty or a refresh was asked for.
      if (subjects.isEmpty || forceRemote) {
        isLoading.value = true;
        try {
          await SyncingController.instance.syncSubjects();
          await loadLocalSubjects();
        } finally {
          isLoading.value = false;
        }
      }
    } catch (_) {
      // Best-effort: whatever is cached stays on screen.
    }
  }

  Future<void> loadPausedTests() async {
    try {
      final rows = await DatabaseService.instance.loadAllInProgressResults();
      pausedTests.assignAll(
        rows.map((r) => PausedTestInfoModel.fromMap(r)).toList(),
      );
    } catch (_) {
      pausedTests.clear();
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
      await loadTestNumbers(subjects);
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

  /// DOWNLOAD SUBJECT (all chapter, grade, entrance, and model exam materials)
  Future<void> downloadSubject(String subject, int subjectId) async {
    // Immediate UI feedback on tap
    downloadingMap[subject] = true;
    subjectDownloadStep[subject] = 'Starting…';
    subjectDownloadProgress[subject] = 0.05;

    try {
      final hasNet = await NetworkManager.instance.hasNetworkInterface();
      if (!hasNet) {
        ToastHelper.warning('No Internet connection!');
        return;
      }

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
    entranceDownloadStep[subject.id] = 'Starting…';
    entranceDownloadProgress[subject.id] = 0.05;

    try {
      final hasNet = await NetworkManager.instance.hasNetworkInterface();
      if (!hasNet) {
        ToastHelper.warning('No Internet connection!');
        return;
      }

      final syncRepo = SyncRepository();
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

  /// REMOVE / DELETE SUBJECT DOWNLOAD FROM DEVICE
  Future<void> deleteSubject(SubjectModel subject) async {
    try {
      isLoading.value = true;
      await _repo.deleteSubject(subject.id);
      await loadLocalSubjects();
      await loadPausedTests();
      ToastHelper.success('${subject.name} removed from device');
    } catch (e) {
      AppExceptionHandler.handleResponse(e);
    } finally {
      isLoading.value = false;
    }
  }

  /// Refreshes entrance/model counts from remote and persists to SQLite.
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
        final newEntrance = remoteEntrance > (entranceTestNumbers[sid] ?? 0)
            ? remoteEntrance
            : (entranceTestNumbers[sid] ?? 0);
        final newModel = remoteModel > (modelTestNumbers[sid] ?? 0)
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
      for (final s in subjects) {
        entranceTestNumbers[s.id] = s.entranceCount;
        modelTestNumbers[s.id] = s.modelCount;
      }

      // If ANY subject has 0 for both counts (never fetched or new subject
      final zeroSubjects = subjects
          .where(
            (s) =>
                (entranceTestNumbers[s.id] ?? 0) == 0 &&
                (modelTestNumbers[s.id] ?? 0) == 0,
          )
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

  List<PausedTestInfoModel> get filteredPausedTests {
    final isNatural = selectedStream.value == 'natural';

    return pausedTests.where((p) {
      if (p.subjectIsCommon == true) return true;
      if (p.subjectIsNatural != null) {
        return p.subjectIsNatural == isNatural;
      }
      return true;
    }).toList();
  }
}
