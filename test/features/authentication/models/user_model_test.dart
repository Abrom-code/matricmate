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
      expect(user.toMap(), {
        'id': 'user-1',
        'first_name': 'Abel',
        'last_name': 'Tesfaye',
        'email': 'abel@example.com',
        'stream': 'Natural',
        'subscription_status': 'active',
      });
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
  });
}
