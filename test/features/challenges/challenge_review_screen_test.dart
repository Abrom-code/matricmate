import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:matricmate/features/challenges/models/challenge_leaderboard_entry.dart';
import 'package:matricmate/features/challenges/models/challenge_question_model.dart';
import 'package:matricmate/features/challenges/screens/challenge_review_screen.dart';

void main() {
  setUp(() {
    Get.testMode = true;
  });

  tearDown(() {
    Get.reset();
  });

  testWidgets('ChallengeReviewScreen builds safely with default/null flags', (tester) async {
    final questions = [
      ChallengeQuestionModel(
        id: 'q1',
        setId: 's1',
        orderIndex: 1,
        questionText: 'What is the capital of Ethiopia?',
        choices: ['Addis Ababa', 'Gondar', 'Hawassa', 'Dire Dawa'],
        correctChoice: '0',
        explanation: 'Addis Ababa is the capital city.',
        explanationEn: 'Addis Ababa is the capital city.',
        explanationAm: 'አዲስ አበባ ዋና ከተማ ናት።',
      ),
      ChallengeQuestionModel(
        id: 'q2',
        setId: 's1',
        orderIndex: 2,
        questionText: 'What is 5 x 5?',
        choices: ['10', '20', '25', '30'],
        correctChoice: '2',
        explanation: '5 * 5 = 25',
      ),
    ];

    await tester.pumpWidget(
      GetMaterialApp(
        home: ChallengeReviewScreen(
          challengeId: 'c1',
          title: 'General Knowledge Challenge',
          questions: questions,
          userAnswers: {'q1': '0', 'q2': '1'},
          score: 1,
          timeSpentSeconds: 65,
          isLive: false,
          isRedo: false,
        ),
      ),
    );

    expect(find.text('Challenge Review'), findsOneWidget);
    expect(find.text('General Knowledge Challenge'), findsOneWidget);
    expect(find.text('Time Taken'), findsOneWidget);
    expect(find.text('01:05'), findsOneWidget);
    expect(find.text('1 / 2'), findsOneWidget);
    expect(find.text('50%'), findsOneWidget);
    expect(find.text('Done'), findsOneWidget);
    expect(find.text('Redo Challenge'), findsOneWidget);
  });

  testWidgets('ChallengeReviewScreen builds safely with isLive: true', (tester) async {
    final questions = [
      ChallengeQuestionModel(
        id: 'q1',
        setId: 's1',
        orderIndex: 1,
        questionText: 'Test question',
        choices: ['A', 'B'],
        correctChoice: '0',
      ),
    ];

    await tester.pumpWidget(
      GetMaterialApp(
        home: ChallengeReviewScreen(
          challengeId: 'c_live',
          title: 'Live Championship',
          questions: questions,
          userAnswers: {'q1': '0'},
          score: 100,
          timeSpentSeconds: 30,
          isLive: true,
          isRedo: false,
        ),
      ),
    );

    expect(find.text('LIVE STANDING'), findsOneWidget);
    expect(find.text('Full Board'), findsOneWidget);
    expect(find.text('View Standings'), findsOneWidget);
    expect(find.text('Practice / Redo Challenge'), findsOneWidget);
  });
}
