import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:matricmate/features/authentication/models/user_model.dart';
import 'package:matricmate/features/challenges/controllers/challenge_archive_controller.dart';
import 'package:matricmate/features/challenges/controllers/challenge_home_controller.dart';
import 'package:matricmate/features/challenges/models/challenge_model.dart';
import 'package:matricmate/features/challenges/screens/widgets/completed_challenge_card.dart';
import 'package:matricmate/features/challenges/screens/widgets/archive_challenge_card.dart';
import 'package:matricmate/features/personalization/controllers/user_controller.dart';

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
  final RxBool isOffline = false.obs;

  @override
  final RxMap<String, bool> isDownloading = <String, bool>{}.obs;

  @override
  final RxMap<String, bool> isOpeningReview = <String, bool>{}.obs;

  @override
  bool canAccess(LeaderboardChallengeModel challenge) => true;

  @override
  bool isAttemptedOrPracticed(String id, {String? setId}) => false;

  @override
  bool isDownloaded(String id, {String? setId}) => true;

  @override
  bool isInProgress(String id) => false;

  @override
  int getParticipantCount(String challengeId) => 10;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeChallengeArchiveController extends GetxController
    implements ChallengeArchiveController {
  @override
  final RxBool isOffline = false.obs;

  @override
  final RxMap<String, bool> isDownloading = <String, bool>{}.obs;

  @override
  final RxMap<String, bool> isOpeningReview = <String, bool>{}.obs;

  @override
  bool canAccess(LeaderboardChallengeModel challenge) => true;

  @override
  bool isAttemptedOrPracticed(String id, {String? setId}) => false;

  @override
  bool isDownloaded(String id, {String? setId}) => true;

  @override
  bool isInProgress(String id) => false;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUp(() {
    Get.testMode = true;
    Get.put<UserController>(FakeUserController());
  });

  tearDown(() {
    Get.reset();
  });

  group('LeaderboardChallengeModel - 3-day completion cutoff logic', () {
    test('Live challenge should allow showing leaderboard', () {
      final challenge = LeaderboardChallengeModel(
        id: 'c1',
        setId: 's1',
        subjectId: 1,
        audience: 'both',
        title: 'Active Championship',
        status: 'live',
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        startsAt: DateTime.now().subtract(const Duration(hours: 2)),
        endsAt: DateTime.now().add(const Duration(hours: 2)),
      );

      expect(challenge.isClosed, isFalse);
      expect(challenge.isCompletedBeforeThreeDays, isFalse);
      expect(challenge.shouldShowLeaderboard, isTrue);
    });

    test('Challenge closed 1 day ago should allow showing leaderboard', () {
      final challenge = LeaderboardChallengeModel(
        id: 'c2',
        setId: 's2',
        subjectId: 1,
        audience: 'both',
        title: 'Recent Challenge',
        status: 'closed',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        startsAt: DateTime.now().subtract(const Duration(days: 2)),
        endsAt: DateTime.now().subtract(const Duration(days: 1)),
      );

      expect(challenge.isClosed, isTrue);
      expect(challenge.isCompletedBeforeThreeDays, isFalse);
      expect(challenge.shouldShowLeaderboard, isTrue);
    });

    test('Challenge closed more than 3 days ago should NOT show leaderboard', () {
      final challenge = LeaderboardChallengeModel(
        id: 'c3',
        setId: 's3',
        subjectId: 1,
        audience: 'both',
        title: 'Old Challenge',
        status: 'closed',
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
        startsAt: DateTime.now().subtract(const Duration(days: 5)),
        endsAt: DateTime.now().subtract(const Duration(days: 3, hours: 2)),
      );

      expect(challenge.isClosed, isTrue);
      expect(challenge.isCompletedBeforeThreeDays, isTrue);
      expect(challenge.shouldShowLeaderboard, isFalse);
    });
  });

  group('CompletedChallengeCard - Standings button display', () {
    testWidgets('Omit Standings button when challenge completed more than 3 days ago', (tester) async {
      final fakeCtrl = Get.put<ChallengeHomeController>(FakeChallengeHomeController());
      final challengeOld = LeaderboardChallengeModel(
        id: 'c_old',
        setId: 's_old',
        subjectId: 1,
        audience: 'both',
        title: 'Challenge From Last Week',
        status: 'closed',
        createdAt: DateTime.now().subtract(const Duration(days: 7)),
        endsAt: DateTime.now().subtract(const Duration(days: 4)),
      );

      await tester.pumpWidget(
        GetMaterialApp(
          home: Scaffold(
            body: CompletedChallengeCard(
              challenge: challengeOld,
              ctrl: fakeCtrl,
              dark: false,
            ),
          ),
        ),
      );

      // Standings button must NOT be present
      expect(find.text('Standings'), findsNothing);
      expect(find.byIcon(Icons.leaderboard_rounded), findsNothing);
      // Practice button is still present
      expect(find.text('Practice'), findsOneWidget);
    });

    testWidgets('Show Standings button when challenge completed within 3 days', (tester) async {
      final fakeCtrl = Get.put<ChallengeHomeController>(FakeChallengeHomeController());
      final challengeRecent = LeaderboardChallengeModel(
        id: 'c_recent',
        setId: 's_recent',
        subjectId: 1,
        audience: 'both',
        title: 'Yesterday Challenge',
        status: 'closed',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        endsAt: DateTime.now().subtract(const Duration(days: 1)),
      );

      await tester.pumpWidget(
        GetMaterialApp(
          home: Scaffold(
            body: CompletedChallengeCard(
              challenge: challengeRecent,
              ctrl: fakeCtrl,
              dark: false,
            ),
          ),
        ),
      );

      // Standings button must be visible for recent completion
      expect(find.text('Standings'), findsOneWidget);
      expect(find.byIcon(Icons.leaderboard_rounded), findsOneWidget);
      expect(find.text('Practice'), findsOneWidget);
    });
  });

  group('ArchiveChallengeCard - Standings button display', () {
    testWidgets('Omit Standings button when archived challenge completed more than 3 days ago', (tester) async {
      final fakeCtrl = Get.put<ChallengeArchiveController>(FakeChallengeArchiveController());
      final challengeOld = LeaderboardChallengeModel(
        id: 'c_archived_old',
        setId: 's_archived_old',
        subjectId: 1,
        audience: 'both',
        title: 'Archived Past Challenge',
        status: 'archived',
        createdAt: DateTime.now().subtract(const Duration(days: 14)),
        endsAt: DateTime.now().subtract(const Duration(days: 10)),
      );

      await tester.pumpWidget(
        GetMaterialApp(
          home: Scaffold(
            body: ArchiveChallengeCard(
              challenge: challengeOld,
              ctrl: fakeCtrl,
              dark: false,
            ),
          ),
        ),
      );

      expect(find.text('Standings'), findsNothing);
      expect(find.byIcon(Icons.leaderboard_rounded), findsNothing);
      expect(find.text('Practice'), findsOneWidget);
    });
  });
}
