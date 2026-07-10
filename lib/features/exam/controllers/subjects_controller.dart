import 'dart:async';

import 'package:get/get.dart';
import 'package:matricmate/data/repositories/exam/subject_repository.dart';
import 'package:matricmate/data/repositories/exam/sync_repository.dart';
import 'package:matricmate/features/exam/controllers/syncing_controller.dart';
import 'package:matricmate/features/exam/models/subject_model.dart';
import 'package:matricmate/features/personalization/controller/user_controller.dart';
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

  /// LOCAL ONLY (startup)
  Future<void> loadLocalSubjects() async {
    try {
      isLoading.value = true;

      final dbSubjects = await _repo.getLocalSubjects();

      subjects.assignAll(
        dbSubjects.map((e) => SubjectModel.fromMap(e)).toList(),
      );
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
        // Load local counts (all 0 at this point)
        await Future.wait(
          subjects.map((s) async {
            entranceTestNumbers[s.id] = await _repo.testNumbers(s.id, 'entrance');
            modelTestNumbers[s.id] = await _repo.testNumbers(s.id, 'model');
          }),
        );

        // Await remote counts so the entrance screen shows numbers immediately
        final isConnected = await NetworkManager.instance.isConnected();
        if (isConnected) {
          final subjectIds = subjects.map((s) => s.id).toList();
          final remoteCounts =
              await _repo.remoteEntranceTestCounts(subjectIds);
          for (final entry in remoteCounts.entries) {
            entranceTestNumbers[entry.key] =
                entry.value['entrance'] ?? 0;
            modelTestNumbers[entry.key] = entry.value['model'] ?? 0;
          }
        }
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

  Future<void> loadTestNumbers(List<SubjectModel> subjects) async {
    try {
      // Load local counts first (instant — SQLite)
      await Future.wait(
        subjects.map((s) async {
          entranceTestNumbers[s.id] = await _repo.testNumbers(s.id, 'entrance');
          modelTestNumbers[s.id] = await _repo.testNumbers(s.id, 'model');
        }),
      );

      // If any subject still shows 0 for both, fetch remote counts in the
      // background so the user can see what's available to download.
      // This is fire-and-forget — never blocks startup or navigation.
      final needsRemote = subjects.any(
        (s) =>
            (entranceTestNumbers[s.id] ?? 0) == 0 &&
            (modelTestNumbers[s.id] ?? 0) == 0,
      );

      if (needsRemote) {
        unawaited(_fetchRemoteCountsIfNeeded(subjects));
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

      for (final entry in remoteCounts.entries) {
        final sid = entry.key;
        // Only fill in if local is still 0 — don't overwrite real local data
        if ((entranceTestNumbers[sid] ?? 0) == 0) {
          entranceTestNumbers[sid] = entry.value['entrance'] ?? 0;
        }
        if ((modelTestNumbers[sid] ?? 0) == 0) {
          modelTestNumbers[sid] = entry.value['model'] ?? 0;
        }
      }
    } catch (_) {
      // Silent — this is best-effort only
    }
  }

  List<SubjectModel> get filteredSubjects {
    final isNatural = selectedStream.value == 'natural';

    return subjects.where((subject) {
      return subject.isCommon || subject.isNatural == isNatural;
    }).toList();
  }
}
