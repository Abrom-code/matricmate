import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:matricmate/features/challenges/controllers/challenge_home_controller.dart';
import 'package:matricmate/features/challenges/models/challenge_model.dart';
import 'package:matricmate/features/challenges/screens/widgets/available_challenge_card.dart';

import 'package:matricmate/features/authentication/models/user_model.dart';
import 'package:matricmate/features/personalization/controllers/user_controller.dart';

class FakeUserController extends GetxController implements UserController {
  @override
  final Rx<UserModel> user = UserModel.empty().obs;

  @override
  final RxBool isAdmin = false.obs;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeChallengeHomeController extends GetxController implements ChallengeHomeController {
  @override
  final Rx<DateTime> now = DateTime.now().obs;

  @override
  bool canAccess(LeaderboardChallengeModel challenge) => true;

  @override
  bool isChallengeCompleted(LeaderboardChallengeModel challenge) => false;

  @override
  bool isInProgress(String id) => false;

  @override
  int getParticipantCount(String challengeId) => 25;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('AvailableChallengeCard Live tag position test', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(() => tester.view.resetPhysicalSize());

    final challenge = LeaderboardChallengeModel(
      id: 'c1',
      setId: 's1',
      subjectId: 1,
      audience: 'both',
      title: 'Synonyms and Antonyms',
      status: 'live',
      subjectName: 'SAT',
      durationSeconds: 1800,
      createdAt: DateTime.now(),
      startsAt: DateTime.now().subtract(const Duration(hours: 1)),
      endsAt: DateTime.now().add(const Duration(hours: 20)),
    );

    Get.put<UserController>(FakeUserController());
    final ctrl = Get.put<ChallengeHomeController>(FakeChallengeHomeController());

    await tester.pumpWidget(
      GetMaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: AvailableChallengeCard(
              challenge: challenge,
              ctrl: ctrl,
              dark: false,
            ),
          ),
        ),
      ),
    );

    final liveFinder = find.text('Live');
    expect(liveFinder, findsOneWidget);

    final liveRect = tester.getRect(liveFinder);
    final cardRect = tester.getRect(find.byType(AvailableChallengeCard));
    final headerRowRect = tester.getRect(find.byType(Row).first);

    // Live tag must be aligned to the top-right of the card and header row
    expect(liveRect.right, closeTo(headerRowRect.right, 1.0));
    expect(liveRect.right, lessThanOrEqualTo(cardRect.right));
    expect(liveRect.top, closeTo(headerRowRect.top, 5.0));
  });
}
