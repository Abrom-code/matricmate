import 'package:flutter_test/flutter_test.dart';
import 'package:matricmate/utils/validators/validators.dart';

void main() {
  group('AppValidator', () {
    test('validates required text and stream fields', () {
      expect(AppValidator.validateEmptyText('Name', null), 'Name is required!');
      expect(AppValidator.validateEmptyText('Name', 'Abel'), isNull);
      expect(AppValidator.validateStream(''), 'Stream is required.');
      expect(AppValidator.validateStream('Natural'), isNull);
    });

    test('validates email addresses', () {
      expect(AppValidator.validateEmail(''), 'Email is required.');
      expect(
        AppValidator.validateEmail('not-an-email'),
        'Invalid email address.',
      );
      expect(AppValidator.validateEmail('abel@example.com'), isNull);
    });

    test('validates URLs with an HTTP scheme and host', () {
      expect(AppValidator.isValidUrl(''), 'Enter valid url');
      expect(AppValidator.isValidUrl('ftp://example.com'), 'Invalid url!');
      expect(AppValidator.isValidUrl('https://example.com/receipt'), isNull);
    });

    test('requires a long enough password with a special character', () {
      expect(
        AppValidator.validatePassword('abc'),
        'Password must be at least 6 characters long.',
      );
      expect(
        AppValidator.validatePassword('abcdef'),
        'Password must contain at least one special character.',
      );
      expect(AppValidator.validatePassword('abcde!'), isNull);
    });

    test('validates ten-digit phone numbers', () {
      expect(
        AppValidator.validatePhoneNumber('123'),
        'Invalid phone number format (10 digits required).',
      );
      expect(AppValidator.validatePhoneNumber('0912345678'), isNull);
    });
  });
}
