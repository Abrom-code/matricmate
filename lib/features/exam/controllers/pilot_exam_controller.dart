import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matricmate/common/widgets/dialogs/download_progress_dialog.dart';
import 'package:matricmate/data/repositories/exam/pilot_exam_repository.dart';
import 'package:matricmate/data/repositories/exam/question_repository.dart';
import 'package:matricmate/data/repositories/exam/test_repository.dart';
import 'package:matricmate/features/authentication/models/user_model.dart';
import 'package:matricmate/features/exam/controllers/review_controller.dart';
import 'package:matricmate/features/exam/models/pilot_exam_model.dart';
import 'package:matricmate/features/exam/models/question_model.dart';
import 'package:matricmate/features/exam/models/result_model.dart';
import 'package:matricmate/features/exam/models/test_model.dart';
import 'package:matricmate/features/exam/screens/ready/ready.dart';
import 'package:matricmate/features/personalization/controllers/user_controller.dart';
import 'package:matricmate/routes/app_routes.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/exceptions/exception_handler.dart';
import 'package:matricmate/utils/helpers/test_access_helper.dart';
import 'package:matricmate/utils/helpers/toast_helper.dart';
import 'package:matricmate/utils/network_manager/network_manager.dart';

class PilotExamController extends GetxController {
  static PilotExamController get instance => Get.find();

  final PilotExamRepository _repo = PilotExamRepository();
  final TestRepository _testRepo = TestRepository();

  final RxList<PilotExamModel> pilotExams = <PilotExamModel>[].obs;
  final RxList<PilotExamSubjectModel> examSubjects = <PilotExamSubjectModel>[].obs;
  final Rxn<PilotExamModel> selectedExam = Rxn<PilotExamModel>();

  final RxMap<int, ResultModel> testResults = <int, ResultModel>{}.obs;
  final RxMap<int, int> testQuestionCounts = <int, int>{}.obs;
  final RxMap<int, bool> testHasQuestions = <int, bool>{}.obs;

  final RxBool isLoading = false.obs;
  final RxBool isLoadingSubjects = false.obs;
  final RxMap<int, PilotExamProgress> examProgressMap = <int, PilotExamProgress>{}.obs;

  // ── Download States ────────────────────────────────────────────────────────
  final RxBool isBulkDownloading = false.obs;
  final RxDouble bulkDownloadProgress = 0.0.obs;
  final RxString bulkDownloadStep = ''.obs;
  final RxInt bulkDownloadCompletedCount = 0.obs;
  final RxMap<int, bool> isSubjectDownloading = <int, bool>{}.obs;
  final RxMap<int, double> subjectDownloadProgress = <int, double>{}.obs;
  final RxBool isDeletingDownloads = false.obs;
  bool _isBulkCancelled = false;

  void cancelBulkDownload() {
    _isBulkCancelled = true;
    isBulkDownloading.value = false;
    DownloadProgressDialog.hide();
    ToastHelper.info('Exam download cancelled.');
  }

  void showActiveDownloadProgressDialog() {
    if (isBulkDownloading.value) {
      DownloadProgressDialog.show(
        title: 'Downloading Pilot Exam',
        subtitle: selectedExam.value?.title ?? 'Pilot Exam Simulation',
        progress: bulkDownloadProgress,
        currentItem: bulkDownloadStep,
        completedCount: bulkDownloadCompletedCount,
        totalCount: examSubjects.length,
        accentColor: AppColors.primary,
        onCancel: cancelBulkDownload,
      );
    }
  }

  @override
  void onInit() {
    super.onInit();
    loadPilotExams();
  }

  PilotExamProgress getProgressForExam(int examId) {
    return examProgressMap[examId] ?? const PilotExamProgress();
  }

  bool _isLoadingPilotExams = false;
  bool _isLoadingSubjectsInternal = false;

  /// Loads all available pilot exams (offline SQLite first, then Supabase if online).
  Future<void> loadPilotExams() async {
    if (_isLoadingPilotExams) return;
    _isLoadingPilotExams = true;
    try {
      isLoading.value = true;

      // 1. Purge legacy dummy seeded records if any
      await _repo.clearLegacyDummySeed();

      // 2. Paint immediately from local SQLite
      final local = await _repo.getLocalPilotExams();
      pilotExams.assignAll(local);
      await loadAllExamProgresses();

      // 3. Refresh from remote Supabase if connected
      final isConnected = await NetworkManager.instance.isConnected();
      if (isConnected) {
        final remote = await _repo.fetchRemotePilotExams();
        if (remote != null) {
          await _repo.syncPilotExams(remote);
          final updated = await _repo.getLocalPilotExams();
          pilotExams.assignAll(updated);
          await loadAllExamProgresses();
        }
      }
    } catch (e) {
      AppExceptionHandler.handleResponse(e);
    } finally {
      isLoading.value = false;
      _isLoadingPilotExams = false;
    }
  }

  /// Computes progress (completed count and score) for all pilot exams.
  Future<void> loadAllExamProgresses() async {
    try {
      final userStream = UserController.instance.user.value.stream.toLowerCase().trim();
      final stream = userStream.isEmpty ? 'natural' : userStream;

      for (final exam in pilotExams) {
        final subjects = await _repo.getLocalPilotExamSubjects(exam.id, stream);
        int completed = 0;
        double totalScore = 0.0;

        for (final s in subjects) {
          final res = await _testRepo.loadSavedResults(s.testId);
          if (res != null && res.isCompleted) {
            completed++;
            final total = res.testQuestions.isNotEmpty ? res.testQuestions.length : s.questionCount;
            if (total > 0) {
              final score = ((res.correctAnswers / total) * 100.0).clamp(0.0, 100.0);
              totalScore += score;
            }
          }
        }

        examProgressMap[exam.id] = PilotExamProgress(
          completedSubjects: completed,
          totalSubjects: subjects.isNotEmpty ? subjects.length : 6,
          totalScore: totalScore,
        );
      }
    } catch (_) {}
  }


  /// Selects a pilot exam and loads its 6 subjects based on user stream.
  void selectExam(PilotExamModel exam) {
    selectedExam.value = exam;
    loadSubjectsForSelectedExam();
  }

  /// Loads the 6 subjects and checks local completion results.
  Future<void> loadSubjectsForSelectedExam() async {
    final exam = selectedExam.value;
    if (exam == null) return;
    if (_isLoadingSubjectsInternal) return;
    _isLoadingSubjectsInternal = true;

    try {
      isLoadingSubjects.value = true;
      examSubjects.clear();
      testResults.clear();
      testQuestionCounts.clear();
      testHasQuestions.clear();

      final userStream = UserController.instance.user.value.stream.toLowerCase().trim();
      final stream = userStream.isEmpty ? 'natural' : userStream;

      // 1. Load subjects from SQLite immediately
      final subjects = await _repo.getLocalPilotExamSubjects(exam.id, stream);
      examSubjects.assignAll(subjects);
      await _loadSubjectTestMetadata(examSubjects);

      // If cached subjects exist locally, unblock UI immediately
      if (examSubjects.isNotEmpty) {
        isLoadingSubjects.value = false;
      }

      // 2. Fetch remote subjects if online and save
      final isConnected = await NetworkManager.instance.isConnected();
      if (isConnected) {
        final remote = await _repo.fetchRemotePilotExamSubjects(exam.id);
        if (remote != null) {
          await _repo.syncPilotExamSubjects(exam.id, remote);
          final updated = await _repo.getLocalPilotExamSubjects(exam.id, stream);
          examSubjects.assignAll(updated);
          await _loadSubjectTestMetadata(examSubjects);
        }
      }

      examProgressMap[exam.id] = PilotExamProgress(
        completedSubjects: completedSubjectsCount,
        totalSubjects: examSubjects.length,
        totalScore: grandTotalScore,
      );
    } catch (e) {
      AppExceptionHandler.handleResponse(e);
    } finally {
      isLoadingSubjects.value = false;
      _isLoadingSubjectsInternal = false;
    }
  }


  Future<void> _loadSubjectTestMetadata(List<PilotExamSubjectModel> subjects) async {
    for (final s in subjects) {
      try {
        final result = await _testRepo.loadSavedResults(s.testId);
        if (result != null) {
          testResults[s.testId] = result;
        }

        final count = await _testRepo.getActualQuestionCount(s.testId);
        testQuestionCounts[s.testId] = count > 0 ? count : s.questionCount;

        final hasQn = await _testRepo.hasQns(s.testId);
        testHasQuestions[s.testId] = hasQn;
      } catch (_) {}
    }
  }

  // ── Score & Progress Calculations ──────────────────────────────────────────

  /// Number of completed subjects out of 6
  int get completedSubjectsCount {
    int count = 0;
    for (final s in examSubjects) {
      final res = testResults[s.testId];
      if (res != null && res.isCompleted) {
        count++;
      }
    }
    return count;
  }

  /// Checks if a subject exam has a completed result
  bool isSubjectCompleted(int testId) {
    final res = testResults[testId];
    return res != null && res.isCompleted;
  }

  /// Checks if a subject exam is paused / in-progress
  bool isSubjectInProgress(int testId) {
    final res = testResults[testId];
    return res != null && !res.isCompleted;
  }

  /// Calculates subject score scaled strictly out of 100
  double getSubjectScoreOutOf100(int testId, int fallbackQnCount) {
    final res = testResults[testId];
    if (res == null) return 0.0;

    final total = res.testQuestions.isNotEmpty
        ? res.testQuestions.length
        : (testQuestionCounts[testId] ?? fallbackQnCount);

    if (total <= 0) return 0.0;
    final score = (res.correctAnswers / total) * 100.0;
    return score.clamp(0.0, 100.0);
  }

  /// Returns actual number of correct answers for a completed subject exam
  int getSubjectCorrectAnswers(int testId) {
    return testResults[testId]?.correctAnswers ?? 0;
  }

  /// Returns actual total question count for a completed or loaded subject exam
  int getSubjectTotalQuestions(int testId, int fallbackQnCount) {
    final res = testResults[testId];
    if (res != null && res.testQuestions.isNotEmpty) {
      return res.testQuestions.length;
    }
    final actualCount = testQuestionCounts[testId];
    if (actualCount != null && actualCount > 0) {
      return actualCount;
    }
    return fallbackQnCount > 0 ? fallbackQnCount : 60;
  }

  /// Sum of all completed subject scores (Grand Total out of 600)
  double get grandTotalScore {
    double total = 0.0;
    for (final s in examSubjects) {
      if (isSubjectCompleted(s.testId)) {
        total += getSubjectScoreOutOf100(s.testId, s.questionCount);
      }
    }
    return total;
  }

  /// Composite average percentage across completed subjects
  double get compositePercentage {
    final count = completedSubjectsCount;
    if (count == 0) return 0.0;
    return (grandTotalScore / (count * 100.0)) * 100.0;
  }

  /// Predicted national performance tier
  String get performanceTier {
    final score = grandTotalScore;
    final count = completedSubjectsCount;

    if (count == 0) return 'Not Started';
    if (count < 6) return 'In Progress ($count/6 completed)';

    if (score >= 500) return 'Top Tier (High Distinction)';
    if (score >= 420) return 'Distinction (University Qualified)';
    if (score >= 350) return 'Satisfactory Pass';
    return 'Needs Target Revision';
  }

  // ── Download Helpers & Status ──────────────────────────────────────────────

  /// Checks if questions are downloaded locally in SQLite for this test
  bool isSubjectDownloaded(int testId) {
    return (testHasQuestions[testId] ?? false) &&
        ((testQuestionCounts[testId] ?? 0) > 0);
  }

  /// Checks if all subjects in the selected exam are ready offline
  bool get isAllSubjectsDownloaded {
    if (examSubjects.isEmpty) return false;
    return examSubjects.every((s) => isSubjectDownloaded(s.testId));
  }

  /// Number of subjects downloaded
  int get downloadedSubjectsCount {
    return examSubjects.where((s) => isSubjectDownloaded(s.testId)).length;
  }

  /// Downloads questions for a single subject test with reactive progress
  Future<bool> downloadSubject(
    PilotExamSubjectModel subject, {
    bool silent = false,
  }) async {
    final testId = subject.testId;
    final user = UserController.instance.user.value;
    if (!user.isActive) {
      if (!silent) {
        TestAccessHelper.openPremiumSheet(user: user);
      }
      return false;
    }

    if (isSubjectDownloaded(testId)) return true;
    if (isSubjectDownloading[testId] == true) return false;

    final isConnected = await NetworkManager.instance.isConnected();
    if (!isConnected) {
      if (!silent) {
        ToastHelper.error('No internet connection. Connect to download exam.');
      }
      return false;
    }

    try {
      isSubjectDownloading[testId] = true;
      subjectDownloadProgress[testId] = 0.05;
      final count = await _repo.downloadSubjectQuestions(
        testId,
        subject.subjectId,
        onStep: (step, progress) {
          subjectDownloadProgress[testId] = progress;
        },
      );

      final localCount = await _testRepo.getActualQuestionCount(testId);
      final hasQn = await _testRepo.hasQns(testId);
      final finalCount = localCount > 0 ? localCount : count;
      testQuestionCounts[testId] = finalCount;
      testHasQuestions[testId] = hasQn && finalCount > 0;

      if (!silent) {
        if (testHasQuestions[testId] == true) {
          ToastHelper.success(
            '${subject.subjectName} downloaded for offline use.',
          );
        } else {
          ToastHelper.info(
            'No questions available online for ${subject.subjectName}.',
          );
        }
      }
      return testHasQuestions[testId] == true;
    } catch (e) {
      if (!silent) {
        AppExceptionHandler.handleResponse(e);
      }
      return false;
    } finally {
      isSubjectDownloading[testId] = false;
      subjectDownloadProgress.remove(testId);
    }
  }

  /// Downloads all subjects in the current pilot exam for complete offline readiness
  Future<void> downloadAllSubjects() async {
    final user = UserController.instance.user.value;
    if (!user.isActive) {
      TestAccessHelper.openPremiumSheet(user: user);
      return;
    }

    if (isBulkDownloading.value) {
      showActiveDownloadProgressDialog();
      return;
    }

    final isConnected = await NetworkManager.instance.isConnected();
    if (!isConnected) {
      ToastHelper.error('No internet connection to download exams.');
      return;
    }

    final toDownload =
        examSubjects.where((s) => !isSubjectDownloaded(s.testId)).toList();
    if (toDownload.isEmpty) {
      ToastHelper.info('All subjects are already downloaded and offline ready.');
      return;
    }

    try {
      _isBulkCancelled = false;
      isBulkDownloading.value = true;
      bulkDownloadProgress.value = 0.0;
      bulkDownloadCompletedCount.value = 0;
      bulkDownloadStep.value = 'Preparing exam download…';

      DownloadProgressDialog.show(
        title: 'Downloading Pilot Exam',
        subtitle: selectedExam.value?.title ?? 'Pilot Exam Simulation',
        progress: bulkDownloadProgress,
        currentItem: bulkDownloadStep,
        completedCount: bulkDownloadCompletedCount,
        totalCount: toDownload.length,
        accentColor: AppColors.primary,
        onCancel: cancelBulkDownload,
      );

      int completed = 0;
      for (final s in toDownload) {
        if (_isBulkCancelled) break;
        bulkDownloadStep.value =
            'Downloading ${s.subjectName} (${completed + 1}/${toDownload.length})…';
        await downloadSubject(s, silent: true);
        completed++;
        bulkDownloadCompletedCount.value = completed;
        bulkDownloadProgress.value = completed / toDownload.length;
      }

      await _loadSubjectTestMetadata(examSubjects);
      if (!_isBulkCancelled) {
        ToastHelper.success('All pilot exam subjects are ready offline!');
      }
    } catch (e) {
      AppExceptionHandler.handleResponse(e);
    } finally {
      isBulkDownloading.value = false;
      bulkDownloadProgress.value = 0.0;
      bulkDownloadCompletedCount.value = 0;
      bulkDownloadStep.value = '';
      DownloadProgressDialog.hide();
    }
  }

  /// Deletes all downloaded questions for the current pilot exam from SQLite
  Future<void> deleteAllExamDownloads() async {
    if (isDeletingDownloads.value || isBulkDownloading.value) return;

    final testIds = examSubjects.map((s) => s.testId).toList();
    if (testIds.isEmpty) return;

    try {
      isDeletingDownloads.value = true;
      await _repo.deleteExamQuestions(testIds);

      // Reset local in-memory question metadata
      for (final id in testIds) {
        testHasQuestions[id] = false;
        testQuestionCounts[id] = 0;
      }

      await _loadSubjectTestMetadata(examSubjects);
      ToastHelper.success('Downloaded exam questions removed from device.');
    } catch (e) {
      AppExceptionHandler.handleResponse(e);
    } finally {
      isDeletingDownloads.value = false;
    }
  }

  /// Opens the Review Screen for a completed subject exam
  Future<void> openSubjectReview(PilotExamSubjectModel subject) async {
    try {
      ResultModel? result = testResults[subject.testId];
      if (result == null) {
        result = await _testRepo.loadSavedResults(subject.testId);
      }

      if (result == null) {
        ToastHelper.info('No saved results found for this exam.');
        return;
      }

      // If test questions were not populated, hydrate from local SQLite
      if (result.testQuestions.isEmpty) {
        final dbQuestions =
            await QuestionRepository().getQnByTestIdLocal(subject.testId);
        if (dbQuestions.isNotEmpty) {
          final qList =
              dbQuestions.map((e) => QuestionModel.fromMap(e)).toList();
          result = ResultModel(
            userId: result.userId,
            testId: result.testId,
            selectedAnswers: result.selectedAnswers,
            testQuestions: qList,
            correctAnswers: result.correctAnswers,
            isCompleted: result.isCompleted,
            checkedQuestions: result.checkedQuestions,
            remainingSeconds: result.remainingSeconds,
          );
        }
      }

      Get.delete<ReviewController>(force: true);
      Get.toNamed(Routes.review, arguments: result);
    } catch (e) {
      AppExceptionHandler.handleResponse(e);
    }
  }

  /// Launches the exam for the given subject in strict Exam Mode (no pause, timed).
  /// If the subject isn't downloaded yet, seamlessly auto-downloads it first!
  Future<void> startSubjectExam(
    PilotExamSubjectModel subject,
    UserModel user,
  ) async {
    if (!user.isActive) {
      TestAccessHelper.openPremiumSheet(user: user);
      return;
    }

    final testId = subject.testId;
    final downloaded = isSubjectDownloaded(testId);

    // If not yet downloaded, trigger seamless auto-download with immediate feedback!
    if (!downloaded) {
      final isConnected = await NetworkManager.instance.isConnected();
      if (!isConnected) {
        ToastHelper.error(
          'This subject is not downloaded yet. Please connect to the internet to download it once.',
        );
        return;
      }

      // Show friendly preparing popup
      Get.dialog(
        PopScope(
          canPop: false,
          child: Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 44,
                    height: 44,
                    child: CircularProgressIndicator(strokeWidth: 3.5),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Preparing ${subject.subjectName} Pilot Exam',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Downloading questions & diagrams for offline simulation…',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
        barrierDismissible: false,
      );

      final success = await downloadSubject(subject, silent: true);
      Get.back(); // Dismiss dialog

      if (!success) {
        ToastHelper.error(
          'Could not download exam questions. Please check connection and try again.',
        );
        return;
      }
    }

    final dummyTest = TestModel(
      id: testId,
      subjectId: subject.subjectId,
      title: '${subject.subjectName} Pilot Exam',
      type: 'pilot',
      time: subject.timeMinutes,
      questionCount: testQuestionCounts[testId] ?? subject.questionCount,
      createdAt: DateTime.now(),
    );

    final existingDraft =
        testResults[testId] != null && !testResults[testId]!.isCompleted
            ? testResults[testId]
            : null;

    TestAccessHelper.handleTestTap(
      test: dummyTest,
      user: user,
      onStart: () {
        Get.to(
          () => ReadyScreen(
            qnCount: testQuestionCounts[testId] ?? subject.questionCount,
            time: subject.timeMinutes,
            testId: testId,
            id: 3, // pilot exam controller id
            draft: existingDraft,
            examTitle:
                '${selectedExam.value?.title ?? "Pilot Exam"} — ${subject.subjectName}',
            description:
                'Subject ${subject.orderIndex} of 6 • ${subject.stream.toUpperCase()} STREAM',
            subjectName: subject.subjectName,
            forceExamMode: true,
            canPause: true,
          ),
        )?.then((_) {
          // Auto reload subject results when student returns from the exam
          loadSubjectsForSelectedExam();
        });
      },
    );
  }
}
