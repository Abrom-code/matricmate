import 'package:flutter_test/flutter_test.dart';
import 'package:matricmate/features/authentication/models/user_model.dart';
import 'package:matricmate/features/challenges/models/challenge_model.dart';
import 'package:matricmate/utils/helpers/challenge_access_helper.dart';

void main() {
  group('LeaderboardChallengeModel isPremium parsing', () {
    test('parses boolean is_premium = false correctly', () {
      final model = LeaderboardChallengeModel.fromJson({
        'id': 'c1',
        'title': 'Free Challenge',
        'audience': 'both',
        'status': 'live',
        'is_premium': false,
      });
      expect(model.isPremium, isFalse);
    });

    test('parses boolean is_premium = true correctly', () {
      final model = LeaderboardChallengeModel.fromJson({
        'id': 'c2',
        'title': 'Premium Challenge',
        'audience': 'both',
        'status': 'live',
        'is_premium': true,
      });
      expect(model.isPremium, isTrue);
    });

    test('parses integer is_premium = 0 as free', () {
      final model = LeaderboardChallengeModel.fromJson({
        'id': 'c3',
        'title': 'Free Challenge Int',
        'audience': 'both',
        'status': 'live',
        'is_premium': 0,
      });
      expect(model.isPremium, isFalse);
    });

    test('parses integer is_premium = 1 as premium', () {
      final model = LeaderboardChallengeModel.fromJson({
        'id': 'c4',
        'title': 'Premium Challenge Int',
        'audience': 'both',
        'status': 'live',
        'is_premium': 1,
      });
      expect(model.isPremium, isTrue);
    });

    test('parses string is_premium = "false" as free', () {
      final model = LeaderboardChallengeModel.fromJson({
        'id': 'c5',
        'title': 'Free Challenge Str',
        'audience': 'both',
        'status': 'live',
        'is_premium': 'false',
      });
      expect(model.isPremium, isFalse);
    });

    test('parses string is_premium = "0" as free', () {
      final model = LeaderboardChallengeModel.fromJson({
        'id': 'c6',
        'title': 'Free Challenge Str Zero',
        'audience': 'both',
        'status': 'live',
        'is_premium': '0',
      });
      expect(model.isPremium, isFalse);
    });

    test('defaults to true when is_premium is null', () {
      final model = LeaderboardChallengeModel.fromJson({
        'id': 'c7',
        'title': 'Default Challenge',
        'audience': 'both',
        'status': 'live',
      });
      expect(model.isPremium, isTrue);
    });

    test('falls back to challenge_question_sets is_premium if not in challenge root', () {
      final model = LeaderboardChallengeModel.fromJson({
        'id': 'c8',
        'title': 'Nested Set Challenge',
        'audience': 'both',
        'status': 'live',
        'challenge_question_sets': {
          'id': 's1',
          'is_premium': false,
        },
      });
      expect(model.isPremium, isFalse);
    });

    test('toJson outputs is_premium integer', () {
      final freeModel = LeaderboardChallengeModel(
        id: 'c9',
        setId: 'c9',
        subjectId: 1,
        audience: 'both',
        title: 'Free Test',
        status: 'live',
        createdAt: DateTime.now(),
        isPremium: false,
      );
      expect(freeModel.toJson()['is_premium'], equals(0));

      final premModel = LeaderboardChallengeModel(
        id: 'c10',
        setId: 'c10',
        subjectId: 1,
        audience: 'both',
        title: 'Pro Test',
        status: 'live',
        createdAt: DateTime.now(),
        isPremium: true,
      );
      expect(premModel.toJson()['is_premium'], equals(1));
    });
  });

  group('ChallengeAccessHelper.canAccess', () {
    final activeUser = UserModel(
      id: 'u1',
      email: 'active@test.com',
      firstName: 'Abebe',
      lastName: 'Kebede',
      stream: 'natural',
      status: 'active',
    );

    final pendingUser = UserModel(
      id: 'u2',
      email: 'pending@test.com',
      firstName: 'Kebede',
      lastName: 'Tesfaye',
      stream: 'natural',
      status: 'pending',
    );

    final inactiveUser = UserModel(
      id: 'u3',
      email: 'inactive@test.com',
      firstName: 'Almaz',
      lastName: 'Desta',
      stream: 'natural',
      status: 'inactive',
    );

    final freeChallenge = LeaderboardChallengeModel(
      id: 'ch-free',
      setId: 'ch-free',
      subjectId: 1,
      audience: 'both',
      title: 'Free Biology Challenge',
      status: 'live',
      createdAt: DateTime.now(),
      isPremium: false,
    );

    final premiumChallenge = LeaderboardChallengeModel(
      id: 'ch-prem',
      setId: 'ch-prem',
      subjectId: 1,
      audience: 'both',
      title: 'Premium Math Challenge',
      status: 'live',
      createdAt: DateTime.now(),
      isPremium: true,
    );

    test('free challenge is accessible to active, pending, and inactive users', () {
      expect(ChallengeAccessHelper.canAccess(challenge: freeChallenge, user: activeUser), isTrue);
      expect(ChallengeAccessHelper.canAccess(challenge: freeChallenge, user: pendingUser), isTrue);
      expect(ChallengeAccessHelper.canAccess(challenge: freeChallenge, user: inactiveUser), isTrue);
    });

    test('premium challenge is accessible to active users only', () {
      expect(ChallengeAccessHelper.canAccess(challenge: premiumChallenge, user: activeUser), isTrue);
      expect(ChallengeAccessHelper.canAccess(challenge: premiumChallenge, user: pendingUser), isFalse);
      expect(ChallengeAccessHelper.canAccess(challenge: premiumChallenge, user: inactiveUser), isFalse);
    });
  });

  group('ChallengeAccessHelper.sortForUser', () {
    final inactiveUser = UserModel(
      id: 'u3',
      email: 'inactive@test.com',
      firstName: 'Almaz',
      lastName: 'Desta',
      stream: 'natural',
      status: 'inactive',
    );

    final activeUser = UserModel(
      id: 'u1',
      email: 'active@test.com',
      firstName: 'Abebe',
      lastName: 'Kebede',
      stream: 'natural',
      status: 'active',
    );

    final c1 = LeaderboardChallengeModel(
      id: '1',
      setId: '1',
      subjectId: 1,
      audience: 'both',
      title: 'Prem 1',
      status: 'live',
      createdAt: DateTime.now(),
      isPremium: true,
    );
    final c2 = LeaderboardChallengeModel(
      id: '2',
      setId: '2',
      subjectId: 1,
      audience: 'both',
      title: 'Free 2',
      status: 'live',
      createdAt: DateTime.now(),
      isPremium: false,
    );
    final c3 = LeaderboardChallengeModel(
      id: '3',
      setId: '3',
      subjectId: 1,
      audience: 'both',
      title: 'Prem 3',
      status: 'live',
      createdAt: DateTime.now(),
      isPremium: true,
    );

    test('places free challenges first for inactive users', () {
      final sorted = ChallengeAccessHelper.sortForUser([c1, c2, c3], inactiveUser);
      expect(sorted.map((c) => c.id).toList(), equals(['2', '1', '3']));
    });

    test('preserves original order for active users', () {
      final sorted = ChallengeAccessHelper.sortForUser([c1, c2, c3], activeUser);
      expect(sorted.map((c) => c.id).toList(), equals(['1', '2', '3']));
    });
  });
}
