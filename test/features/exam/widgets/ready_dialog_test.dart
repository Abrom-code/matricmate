import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:matricmate/features/exam/models/result_model.dart';
import 'package:matricmate/features/exam/screens/ready/ready.dart';

void main() {
  Future<void> pumpReadyScreen(
    WidgetTester tester, {
    ResultModel? draft,
    String? title,
  }) {
    return tester.pumpWidget(
      GetMaterialApp(
        home: ReadyScreen(
          qnCount: 100,
          time: 120,
          testId: 41,
          id: 7,
          draft: draft,
          examTitle: title,
        ),
      ),
    );
  }

  testWidgets('shows exam title and both mode cards without right check icon', (
    tester,
  ) async {
    await pumpReadyScreen(tester, title: '2023 Physics 4');

    expect(find.text('Test Overview'), findsOneWidget);
    expect(find.text('2023 Physics 4'), findsOneWidget);
    expect(find.text('Practice Mode'), findsOneWidget);
    expect(find.text('Real Exam Mode'), findsOneWidget);
    expect(find.byIcon(Icons.check_rounded), findsNothing);
    expect(find.text('Start in Practice Mode'), findsOneWidget);
  });

  testWidgets('offers resume banner and button for an in-progress draft', (
    tester,
  ) async {
    final draft = ResultModel(
      testQuestions: [],
      selectedAnswers: {1: 2, 2: 1},
      correctAnswers: 0,
      testId: 41,
      userId: 'student-1',
      isCompleted: false,
      remainingSeconds: 3600,
    );

    await pumpReadyScreen(tester, draft: draft, title: 'Chemistry Final');

    expect(find.text('Paused Attempt In Progress'), findsOneWidget);
    expect(find.text('Resume from Question 3'), findsOneWidget);
    expect(find.textContaining('Start Fresh'), findsOneWidget);
  });

  testWidgets('ReadyDialog adapter renders ReadyScreen correctly', (
    tester,
  ) async {
    await tester.pumpWidget(
      const GetMaterialApp(
        home: Scaffold(
          body: ReadyDialog(
            qnCount: 50,
            time: 60,
            testId: 10,
            id: 1,
            examTitle: 'Grade 11 Biology',
          ),
        ),
      ),
    );

    expect(find.text('Grade 11 Biology'), findsOneWidget);
    expect(find.text('Practice Mode'), findsOneWidget);
    expect(find.text('Real Exam Mode'), findsOneWidget);
  });
}
