import 'package:flutter_test/flutter_test.dart';
import 'package:matricmate/features/exam/models/pilot_exam_model.dart';
import 'package:matricmate/features/exam/models/result_model.dart';

void main() {
  group('Pilot Exam Redo Logic Tests', () {
    test('PilotExamProgress calculates progressFraction correctly', () {
      const progress = PilotExamProgress(
        completedSubjects: 3,
        totalSubjects: 6,
        totalScore: 240.0,
      );

      expect(progress.completedSubjects, 3);
      expect(progress.totalSubjects, 6);
      expect(progress.totalScore, 240.0);
      expect(progress.progressFraction, 0.5);
      expect(progress.isStarted, isTrue);
      expect(progress.isCompleted, isFalse);
    });

    test('Subject model parses and maps correctly', () {
      final subject = PilotExamSubjectModel(
        id: 1,
        pilotExamId: 10,
        subjectId: 101,
        subjectName: 'Mathematics',
        stream: 'natural',
        orderIndex: 1,
        questionCount: 60,
        timeMinutes: 120,
        testId: 501,
      );

      expect(subject.subjectName, 'Mathematics');
      expect(subject.testId, 501);
      expect(subject.timeMinutes, 120);

      final map = subject.toMap();
      expect(map['test_id'], 501);
      expect(map['pilot_exam_id'], 10);

      final parsed = PilotExamSubjectModel.fromMap(map);
      expect(parsed.testId, 501);
      expect(parsed.subjectName, 'Mathematics');
    });

    test('Completed test result can be cleared for redo', () {
      final resultsMap = <int, ResultModel>{};
      final result = ResultModel(
        userId: 'user-1',
        testId: 501,
        selectedAnswers: {1: 2, 2: 3},
        testQuestions: [],
        correctAnswers: 2,
        isCompleted: true,
      );

      resultsMap[501] = result;
      expect(resultsMap.containsKey(501), isTrue);
      expect(resultsMap[501]!.isCompleted, isTrue);

      // Simulating redo: remove from in-memory results map
      resultsMap.remove(501);
      expect(resultsMap.containsKey(501), isFalse);
    });
  });
}
