import 'package:flutter_test/flutter_test.dart';
import 'package:matricmate/features/authentication/models/user_model.dart';
import 'package:matricmate/features/exam/models/test_model.dart';
import 'package:matricmate/utils/helpers/test_access_helper.dart';

void main() {
  group('TestAccessHelper.canAccess', () {
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

    for (final testType in ['chapter', 'grade', 'entrance', 'model']) {
      group('for $testType test type', () {
        final freeTest = TestModel(
          id: 101,
          subjectId: 1,
          questionCount: 20,
          createdAt: DateTime.parse('2026-01-01T00:00:00.000Z'),
          type: testType,
          title: '$testType Test (Free)',
          time: 30,
          isPremium: false,
        );

        final premiumTest = TestModel(
          id: 102,
          subjectId: 1,
          questionCount: 20,
          createdAt: DateTime.parse('2026-01-01T00:00:00.000Z'),
          type: testType,
          title: '$testType Test (Premium)',
          time: 30,
          isPremium: true,
        );

        test('free test is accessible to active, pending, and inactive users', () {
          expect(
            TestAccessHelper.canAccess(test: freeTest, user: activeUser),
            isTrue,
          );
          expect(
            TestAccessHelper.canAccess(test: freeTest, user: pendingUser),
            isTrue,
          );
          expect(
            TestAccessHelper.canAccess(test: freeTest, user: inactiveUser),
            isTrue,
          );
        });

        test('premium test is only accessible to active users', () {
          expect(
            TestAccessHelper.canAccess(test: premiumTest, user: activeUser),
            isTrue,
          );
          expect(
            TestAccessHelper.canAccess(test: premiumTest, user: pendingUser),
            isFalse,
          );
          expect(
            TestAccessHelper.canAccess(test: premiumTest, user: inactiveUser),
            isFalse,
          );
        });
      });
    }
  });
}
