import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:matricmate/features/exam/models/question_model.dart';
import 'package:matricmate/features/exam/models/result_model.dart';
import 'package:matricmate/features/exam/models/subject_model.dart';
import 'package:matricmate/features/exam/models/test_model.dart';

void main() {
  group('SubjectModel entrance exam state', () {
    test('round-trips download state and cached entrance/model counts', () {
      final subject = SubjectModel(
        id: 7,
        name: 'Physics',
        isNatural: true,
        isCommon: false,
        isDownloaded: true,
        isEntranceDownloaded: true,
        entranceCount: 12,
        modelCount: 3,
      );

      final restored = SubjectModel.fromMap(subject.toMap());

      expect(restored.isEntranceDownloaded, isTrue);
      expect(restored.entranceCount, 12);
      expect(restored.modelCount, 3);
      expect(restored.isDownloaded, isTrue);
    });

    test(
      'uses safe defaults for subjects stored before entrance fields existed',
      () {
        final subject = SubjectModel.fromMap({
          'id': 7,
          'name': 'Physics',
          'is_natural': 1,
          'is_common': 0,
          'is_downloaded': 1,
        });

        expect(subject.isEntranceDownloaded, isFalse);
        expect(subject.entranceCount, 0);
        expect(subject.modelCount, 0);
      },
    );
  });

  group('Entrance exam models', () {
    test('preserves nullable test metadata and an untimed entrance exam', () {
      final exam = TestModel.fromMap({
        'id': 41,
        'subject_id': 7,
        'question_count': 100,
        'grade': null,
        'chapter_id': null,
        'created_at': '2026-07-01T09:00:00.000Z',
        'type': 'entrance',
        'title': '2023 Physics 4',
      });

      expect(exam.type, 'entrance');
      expect(exam.time, -1);
      expect(exam.grade, isNull);
      expect(exam.chapterId, isNull);
      expect(exam.toMap()['created_at'], '2026-07-01T09:00:00.000Z');
    });

    test('labels recently published entrance exams as new', () {
      final exam = TestModel(
        id: 41,
        subjectId: 7,
        questionCount: 100,
        createdAt: DateTime.now().subtract(const Duration(hours: 47)),
        type: 'entrance',
        title: '2023 Physics 4',
        time: 120,
      );

      expect(exam.isNew, isTrue);
    });

    test('does not label entrance exams older than two days as new', () {
      final exam = TestModel(
        id: 41,
        subjectId: 7,
        questionCount: 100,
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        type: 'entrance',
        title: '2023 Physics 4',
        time: 120,
      );

      expect(exam.isNew, isFalse);
    });
  });

  group('Entrance exam drafts', () {
    test(
      'round-trips selected answers, revealed questions, and timer state',
      () {
        final question = QuestionModel(
          id: 11,
          subjectId: 7,
          grade: null,
          testId: 41,
          correctOptionIndex: 2,
          questionText: 'Which option is correct?',
          options: ['A', 'B', 'C', 'D'],
        );
        final draft = ResultModel(
          testQuestions: [question],
          selectedAnswers: {11: 2},
          correctAnswers: 1,
          testId: 41,
          userId: 'student-1',
          isCompleted: false,
          checkedQuestions: {11},
          remainingSeconds: 5400,
        );

        final stored = draft.toMap();
        final restored = ResultModel.fromMap(stored);

        expect(restored.isCompleted, isFalse);
        expect(restored.selectedAnswers, {11: 2});
        expect(restored.checkedQuestions, {11});
        expect(restored.remainingSeconds, 5400);
        expect(restored.testQuestions.single.options, ['A', 'B', 'C', 'D']);
      },
    );

    test('accepts legacy rows that have no draft-only fields', () {
      final result = ResultModel.fromMap({
        'testQuestions': jsonEncode([]),
        'selectedAnswers': jsonEncode({}),
        'correctAnswers': 0,
        'test_id': 41,
        'user_id': 'student-1',
      });

      expect(result.isCompleted, isTrue);
      expect(result.checkedQuestions, isEmpty);
      expect(result.remainingSeconds, 0);
    });
  });
}
