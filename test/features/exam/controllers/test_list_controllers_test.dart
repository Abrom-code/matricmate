import 'package:flutter_test/flutter_test.dart';
import 'package:matricmate/data/database/database_service.dart';
import 'package:matricmate/data/repositories/exam/test_repository.dart';
import 'package:matricmate/features/exam/controllers/chapter_test_controller.dart';
import 'package:matricmate/features/exam/controllers/entrance_exams_controller.dart';
import 'package:matricmate/features/exam/controllers/grade_test_controller.dart';
import 'package:matricmate/features/exam/models/question_model.dart';
import 'package:matricmate/features/exam/models/result_model.dart';

class FakeTestRepository extends TestRepository {
  FakeTestRepository({
    required this.tests,
    this.questionFlags = const {},
    this.questionCounts = const {},
    this.results = const {},
  }) : super(databaseService: DatabaseService());

  final List<Map<String, dynamic>> tests;
  final Map<int, bool> questionFlags;
  final Map<int, int> questionCounts;
  final Map<int, ResultModel> results;

  @override
  Future<List<Map<String, dynamic>>> getLocalTests({
    required int subjectId,
    int? grade,
    String? type,
    int? chapterId,
  }) async {
    return tests.where((test) {
      return test['subject_id'] == subjectId &&
          (grade == null || test['grade'] == grade) &&
          (type == null || test['type'] == type) &&
          (chapterId == null || test['chapter_id'] == chapterId);
    }).toList();
  }

  @override
  Future<bool> hasQns(int testId) async => questionFlags[testId] ?? false;

  @override
  Future<int> getActualQuestionCount(int testId) async =>
      questionCounts[testId] ?? 0;

  @override
  Future<ResultModel?> loadSavedResults(int testId) async => results[testId];
}

Map<String, dynamic> testRow({
  required int id,
  required String type,
  int? grade,
  int? chapterId,
  String title = '2023 Physics 1',
}) {
  return {
    'id': id,
    'subject_id': 7,
    'question_count': 100,
    'grade': grade,
    'chapter_id': chapterId,
    'created_at': '2026-07-01T09:00:00.000Z',
    'type': type,
    'title': title,
    'time': 120,
  };
}

ResultModel draftFor(int testId) => ResultModel(
  testQuestions: [question(testId), question(testId + 100)],
  selectedAnswers: {1: 2},
  correctAnswers: 1,
  testId: testId,
  userId: 'student-1',
  isCompleted: false,
);

QuestionModel question(int id) {
  return QuestionModel(
    id: id,
    subjectId: 7,
    grade: 12,
    testId: 41,
    correctOptionIndex: 0,
    questionText: 'Question $id',
    options: const ['A', 'B'],
  );
}

void main() {
  final repository = FakeTestRepository(
    tests: [
      testRow(id: 1, type: 'entrance', title: '2022 Physics 1'),
      testRow(id: 2, type: 'entrance', title: '2024 Physics 2'),
      testRow(id: 3, type: 'model', title: 'Model physics'),
      testRow(id: 4, type: 'grade', grade: 12),
      testRow(id: 5, type: 'chapter', grade: 12, chapterId: 9),
    ],
    questionFlags: {1: true, 2: true, 3: false, 4: true, 5: true},
    questionCounts: {1: 90, 2: 100, 3: 50, 4: 40, 5: 25},
    results: {2: draftFor(2), 4: draftFor(4)},
  );

  group('ExamsController', () {
    test(
      'loads entrance/model tests, sorts them, and exposes local progress',
      () async {
        final controller = EntranceExamsController(testRepository: repository);

        await controller.loadAllExams(7);

        expect(controller.entranceTests.map((test) => test.id), [2, 1]);
        expect(controller.modelTests.single.id, 3);
        expect(controller.testHasQuestions, {1: true, 2: true, 3: false});
        expect(controller.testQuestionCounts[2], 100);
        expect(controller.getCurrentStep(2), 1);
        expect(controller.getCorrectAnswers(2), 1);
        expect(controller.isInProgress(2), isTrue);
        expect(controller.getMaxStep(1), 100);
        expect(controller.isLoading, isFalse);
      },
    );
  });

  group('GradeTestController', () {
    test(
      'loads only the selected grade and uses saved results for progress',
      () async {
        final controller = GradeTestController(testRepository: repository);

        await controller.loadTests(7, 12);

        expect(controller.chapterTests.map((test) => test.id), [4]);
        expect(controller.testHasQuestions[4], isTrue);
        expect(controller.testQuestionCounts[4], 40);
        expect(controller.getCurrentStep(4), 1);
        expect(controller.getMaxStep(4), 2);
      },
    );
  });

  group('ChapterTestController', () {
    test(
      'filters chapter tests and falls back to local question counts',
      () async {
        final controller = ChapterTestController(testRepository: repository);
        controller.chapterId.value = 9;

        await controller.loadGradeTests(7, 12);

        expect(controller.chapterTest.map((test) => test.id), [5]);
        expect(controller.getTestsByGradeAndChapter(12, 9), hasLength(1));
        expect(controller.getTestsByGradeAndChapter(null, 9), hasLength(1));
        expect(controller.getMaxStep(5), 25);
      },
    );
  });
}
