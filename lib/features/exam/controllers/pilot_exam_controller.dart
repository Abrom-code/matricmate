import 'package:get/get.dart';
import 'package:matricmate/data/repositories/exam/pilot_exam_repository.dart';
import 'package:matricmate/data/repositories/exam/test_repository.dart';
import 'package:matricmate/features/authentication/models/user_model.dart';
import 'package:matricmate/features/exam/models/pilot_exam_model.dart';
import 'package:matricmate/features/exam/models/result_model.dart';
import 'package:matricmate/features/exam/models/test_model.dart';
import 'package:matricmate/features/exam/screens/ready/ready.dart';
import 'package:matricmate/features/personalization/controllers/user_controller.dart';
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

  @override
  void onInit() {
    super.onInit();
    loadPilotExams();
  }

  PilotExamProgress getProgressForExam(int examId) {
    return examProgressMap[examId] ?? const PilotExamProgress();
  }

  /// Loads all available pilot exams (offline SQLite first, then Supabase if online).
  Future<void> loadPilotExams() async {
    try {
      isLoading.value = true;

      // 1. Paint immediately from local SQLite
      final local = await _repo.getLocalPilotExams();
      pilotExams.assignAll(local);
      await loadAllExamProgresses();

      // 2. Refresh from remote Supabase if connected
      final isConnected = await NetworkManager.instance.isConnected();
      if (isConnected) {
        final remote = await _repo.fetchRemotePilotExams();
        if (remote.isNotEmpty) {
          await _repo.savePilotExamsBatch(remote);
          final updated = await _repo.getLocalPilotExams();
          pilotExams.assignAll(updated);
          await loadAllExamProgresses();
        }
      }
    } catch (e) {
      AppExceptionHandler.handleResponse(e);
    } finally {
      isLoading.value = false;
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
  Future<void> selectExam(PilotExamModel exam) async {
    selectedExam.value = exam;
    await loadSubjectsForSelectedExam();
  }

  /// Loads the 6 subjects and checks local completion results.
  Future<void> loadSubjectsForSelectedExam() async {
    final exam = selectedExam.value;
    if (exam == null) return;

    try {
      isLoadingSubjects.value = true;
      examSubjects.clear();
      testResults.clear();
      testQuestionCounts.clear();
      testHasQuestions.clear();

      final userStream = UserController.instance.user.value.stream.toLowerCase().trim();
      final stream = userStream.isEmpty ? 'natural' : userStream;

      // 1. Load subjects from SQLite
      final subjects = await _repo.getLocalPilotExamSubjects(exam.id, stream);
      examSubjects.assignAll(subjects);

      // 2. Fetch remote subjects if online and save
      final isConnected = await NetworkManager.instance.isConnected();
      if (isConnected) {
        final remote = await _repo.fetchRemotePilotExamSubjects(exam.id);
        if (remote.isNotEmpty) {
          await _repo.savePilotExamSubjectsBatch(remote);
          final updated = await _repo.getLocalPilotExamSubjects(exam.id, stream);
          examSubjects.assignAll(updated);
        }
      }

      // 3. Load test results and question counts for each subject test
      await _loadSubjectTestMetadata(examSubjects);

      examProgressMap[exam.id] = PilotExamProgress(
        completedSubjects: completedSubjectsCount,
        totalSubjects: examSubjects.length,
        totalScore: grandTotalScore,
      );
    } catch (e) {
      AppExceptionHandler.handleResponse(e);
    } finally {
      isLoadingSubjects.value = false;
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

  /// Launches the exam for the given subject
  void startSubjectExam(PilotExamSubjectModel subject, UserModel user) {
    final testId = subject.testId;
    final hasQn = testHasQuestions[testId] ?? true;

    if (!hasQn) {
      ToastHelper.info('Exam questions for this subject are downloading...');
      return;
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

    TestAccessHelper.handleTestTap(
      test: dummyTest,
      user: user,
      onStart: () {
        final draft = testResults[testId];
        Get.to(
          () => ReadyScreen(
            qnCount: testQuestionCounts[testId] ?? subject.questionCount,
            time: subject.timeMinutes,
            testId: testId,
            id: 2, // exam mode
            examTitle: '${selectedExam.value?.title ?? "Pilot Exam"} — ${subject.subjectName}',
            description:
                'Subject ${subject.orderIndex} of 6 • ${subject.stream.toUpperCase()} STREAM',
            subjectName: subject.subjectName,
            draft: (draft != null && !draft.isCompleted) ? draft : null,
          ),
        )?.then((_) {
          // Auto reload subject results when student returns from the exam
          loadSubjectsForSelectedExam();
        });
      },
    );
  }
}
