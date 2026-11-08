import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:matricmate/features/authentication/models/user_model.dart';
import 'package:matricmate/features/challenges/controllers/challenge_home_controller.dart';
import 'package:matricmate/features/challenges/models/challenge_model.dart';
import 'package:matricmate/features/challenges/screens/leaderboard_screen.dart';
import 'package:matricmate/features/challenges/screens/widgets/available_challenge_card.dart';
import 'package:matricmate/features/personalization/controllers/user_controller.dart';
import 'package:matricmate/routes/app_routes.dart';

class FakeUserController extends GetxController implements UserController {
  @override
  final Rx<UserModel> user = UserModel.empty().obs;

  @override
  final RxBool isAdmin = false.obs;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeChallengeHomeController extends GetxController
    implements ChallengeHomeController {
  @override
  final Rx<DateTime> now = DateTime.now().obs;

  @override
  bool canAccess(LeaderboardChallengeModel challenge) => true;

  @override
  bool isChallengeCompleted(LeaderboardChallengeModel challenge) => false;

  @override
  bool isInProgress(String id) => false;

  @override
  int getParticipantCount(String challengeId) => 10;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late FakeUserController fakeUserCtrl;
  late FakeChallengeHomeController fakeHomeCtrl;

  setUp(() {
    Get.reset();
    fakeUserCtrl =
        Get.put<UserController>(FakeUserController()) as FakeUserController;
    fakeHomeCtrl = Get.put<ChallengeHomeController>(
      FakeChallengeHomeController(),
    ) as FakeChallengeHomeController;
  });

  tearDown(() {
    Get.reset();
  });

  final challenge = LeaderboardChallengeModel(
    id: 'c1',
    setId: 's1',
    subjectId: 1,
    audience: 'both',
    title: 'Test Live Challenge',
    status: 'live',
    subjectName: 'English',
    durationSeconds: 1800,
    createdAt: DateTime.now(),
    startsAt: DateTime.now().subtract(const Duration(hours: 1)),
    endsAt: DateTime.now().add(const Duration(hours: 20)),
  );

  testWidgets(
    'free user tapping "View rankings →" navigates directly to premium screen',
    (tester) async {
      fakeUserCtrl.user.value = UserModel(
        id: 'u_free',
        email: 'free@test.com',
        firstName: 'Free',
        lastName: 'User',
        stream: 'natural',
        status: 'inactive',
      );
      fakeUserCtrl.isAdmin.value = false;

      await tester.pumpWidget(
        GetMaterialApp(
          getPages: [
            GetPage(
              name: Routes.premium,
              page: () => const Scaffold(body: Text('Premium Screen')),
            ),
            GetPage(
              name: Routes.paymentVerification,
              page: () =>
                  const Scaffold(body: Text('Payment Verification Screen')),
            ),
          ],
          home: Scaffold(
            body: AvailableChallengeCard(
              challenge: challenge,
              ctrl: fakeHomeCtrl,
              dark: false,
            ),
          ),
        ),
      );

      final viewRankings = find.text('View rankings →');
      expect(viewRankings, findsOneWidget);

      await tester.tap(viewRankings);
      await tester.pumpAndSettle();

      expect(find.text('Premium Screen'), findsOneWidget);
    },
  );

  testWidgets(
    'pending user tapping "View rankings →" navigates directly to payment verification',
    (tester) async {
      fakeUserCtrl.user.value = UserModel(
        id: 'u_pending',
        email: 'pending@test.com',
        firstName: 'Pending',
        lastName: 'User',
        stream: 'natural',
        status: 'pending',
      );
      fakeUserCtrl.isAdmin.value = false;

      await tester.pumpWidget(
        GetMaterialApp(
          getPages: [
            GetPage(
              name: Routes.premium,
              page: () => const Scaffold(body: Text('Premium Screen')),
            ),
            GetPage(
              name: Routes.paymentVerification,
              page: () =>
                  const Scaffold(body: Text('Payment Verification Screen')),
            ),
          ],
          home: Scaffold(
            body: AvailableChallengeCard(
              challenge: challenge,
              ctrl: fakeHomeCtrl,
              dark: false,
            ),
          ),
        ),
      );

      final viewRankings = find.text('View rankings →');
      expect(viewRankings, findsOneWidget);

      await tester.tap(viewRankings);
      await tester.pumpAndSettle();

      expect(find.text('Payment Verification Screen'), findsOneWidget);
    },
  );

  testWidgets(
    'LeaderboardScreen redirects free user to premium screen if navigated directly',
    (tester) async {
      fakeUserCtrl.user.value = UserModel(
        id: 'u_free',
        email: 'free@test.com',
        firstName: 'Free',
        lastName: 'User',
        stream: 'natural',
        status: 'inactive',
      );
      fakeUserCtrl.isAdmin.value = false;

      await tester.pumpWidget(
        GetMaterialApp(
          getPages: [
            GetPage(
              name: Routes.premium,
              page: () => const Scaffold(body: Text('Premium Screen')),
            ),
            GetPage(
              name: Routes.paymentVerification,
              page: () =>
                  const Scaffold(body: Text('Payment Verification Screen')),
            ),
          ],
          home: const LeaderboardScreen(
            challengeId: 'c1',
            challengeTitle: 'Test Live Challenge',
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Premium Screen'), findsOneWidget);
    },
  );
}
