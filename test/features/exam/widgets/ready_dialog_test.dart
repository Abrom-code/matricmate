import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:matricmate/features/exam/models/result_model.dart';
import 'package:matricmate/features/exam/screens/ready/ready.dart';

void main() {
  Future<void> pumpReadyDialog(
    WidgetTester tester, {
    ResultModel? draft,
    String? title,
  }) {
    return tester.pumpWidget(
      GetMaterialApp(
        home: Scaffold(
          body: ReadyDialog(
            qnCount: 100,
            time: 120,
            testId: 41,
            id: 7,
            draft: draft,
            examTitle: title,
          ),
        ),
      ),
    );
  }

  testWidgets('shows entrance year, code, and both start modes', (
    tester,
  ) async {
    await pumpReadyDialog(tester, title: '2023 Physics 4');

    expect(find.text('Ready to start?'), findsOneWidget);
    expect(find.text('2023'), findsOneWidget);
    expect(find.text('B Code: 4'), findsOneWidget);
    expect(find.text('Practice'), findsOneWidget);
    expect(find.text('Exam'), findsOneWidget);
  });

  testWidgets('offers resume details for an in-progress exam draft', (
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

    await pumpReadyDialog(tester, draft: draft);

    expect(find.text('Continue?'), findsOneWidget);
    expect(find.text('Resume'), findsOneWidget);
    expect(find.textContaining('question 3'), findsOneWidget);
  });
}
