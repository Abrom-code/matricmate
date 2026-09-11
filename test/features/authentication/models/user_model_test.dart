import 'package:flutter_test/flutter_test.dart';
import 'package:matricmate/features/authentication/models/user_model.dart';

void main() {
  group('UserModel', () {
    final user = UserModel(
      id: 'user-1',
      firstName: 'Abel',
      lastName: 'Tesfaye',
      email: 'abel@example.com',
      stream: 'Natural',
      password: 'secret',
      status: 'active',
    );

    test('serializes the fields persisted locally and remotely', () {
      expect(user.toJson(), {
        'id': 'user-1',
        'first_name': 'Abel',
        'last_name': 'Tesfaye',
        'email': 'abel@example.com',
        'stream': 'Natural',
        'subscription_status': 'active',
      });
      expect(user.toMap()['id'], 'user-1');
      expect(user.toMap()['first_name'], 'Abel');
      expect(user.toMap()['subscription_status'], 'active');
    });

    test('uses safe defaults for missing remote fields', () {
      final restored = UserModel.fromJson({'id': 'user-1'});

      expect(restored.fullName, ' ');
      expect(restored.status, 'inactive');
      expect(restored.isInactive, isTrue);
    });

    test('copies only the supplied fields and exposes status helpers', () {
      final pending = user.copyWith(firstName: 'Sara', status: 'pending');

      expect(pending.fullName, 'Sara Tesfaye');
      expect(pending.email, 'abel@example.com');
      expect(pending.isPending, isTrue);
      expect(pending.isActive, isFalse);
    });

    test('correctly evaluates exceededUploadLimit threshold', () {
      final userZero = UserModel(
        id: 'u1',
        firstName: 'A',
        lastName: 'B',
        email: 'a@b.com',
        stream: 'natural',
        receiptUploadCount: 0,
      );
      expect(userZero.exceededUploadLimit, isFalse);

      final userOne = userZero.copyWith(receiptUploadCount: 1);
      expect(userOne.exceededUploadLimit, isFalse);

      final userTwo = userZero.copyWith(receiptUploadCount: 2);
      expect(userTwo.exceededUploadLimit, isFalse);

      final userThree = userZero.copyWith(receiptUploadCount: 3);
      expect(userThree.exceededUploadLimit, isTrue);

      final userFour = userZero.copyWith(receiptUploadCount: 4);
      expect(userFour.exceededUploadLimit, isTrue);
    });

    test('toJson excludes server-managed fields to prevent client overrides', () {
      final premiumUser = UserModel(
        id: 'u-prem',
        firstName: 'First',
        lastName: 'Last',
        email: 'prem@example.com',
        stream: 'social',
        status: 'active',
        receiptUploadCount: 2,
        subscriptionPlan: '1_year',
        subscriptionExpiresAt: DateTime.utc(2026, 12, 31),
      );

      final json = premiumUser.toJson();
      expect(json.containsKey('receipt_upload_count'), isFalse);
      expect(json.containsKey('subscription_plan'), isFalse);
      expect(json.containsKey('subscription_expires_at'), isFalse);
      expect(json['first_name'], 'First');
      expect(json['stream'], 'social');
    });

    test('parses subscription dates and plan from Supabase payload', () {
      final raw = {
        'id': 'u-sub',
        'first_name': 'Hana',
        'last_name': 'Bekele',
        'email': 'hana@example.com',
        'stream': 'natural',
        'subscription_status': 'active',
        'receipt_upload_count': 1,
        'subscription_plan': '1_month',
        'subscription_expires_at': '2026-10-15T12:00:00.000Z',
      };

      final parsed = UserModel.fromJson(raw);
      expect(parsed.subscriptionPlan, '1_month');
      expect(parsed.receiptUploadCount, 1);
      expect(parsed.subscriptionExpiresAt, isNotNull);
      expect(parsed.subscriptionExpiresAt!.year, 2026);
      expect(parsed.subscriptionExpiresAt!.month, 10);
      expect(parsed.isActive, isTrue);
    });
  });
}
