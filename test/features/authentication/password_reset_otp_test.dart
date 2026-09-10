import 'package:flutter_test/flutter_test.dart';
import 'package:matricmate/utils/validators/validators.dart';

void main() {
  group('Password Reset OTP & Password Validation Tests', () {
    test('validateEmail correctly accepts valid emails and rejects invalid ones', () {
      expect(AppValidator.validateEmail(''), 'Email is required.');
      expect(AppValidator.validateEmail(null), 'Email is required.');
      expect(AppValidator.validateEmail('invalid-email'), 'Invalid email address.');
      expect(AppValidator.validateEmail('user@'), 'Invalid email address.');
      expect(AppValidator.validateEmail('user@domain'), 'Invalid email address.');
      expect(AppValidator.validateEmail('student@matricet.com'), isNull);
    });

    test('validatePassword enforces minimum length and special characters', () {
      expect(AppValidator.validatePassword(''), 'Password is required.');
      expect(AppValidator.validatePassword('12345'), 'Password must be at least 6 characters long.');
      expect(AppValidator.validatePassword('password123'), 'Password must contain at least one special character.');
      expect(AppValidator.validatePassword('Pass@123'), isNull);
    });

    test('validateConfirmPassword enforces matching passwords', () {
      expect(AppValidator.validateConfirmPassword('', 'Pass@123'), 'Please confirm your password.');
      expect(AppValidator.validateConfirmPassword('Pass@456', 'Pass@123'), 'Passwords do not match.');
      expect(AppValidator.validateConfirmPassword('Pass@123', 'Pass@123'), isNull);
    });

    test('Masked email logic masks username and preserves domain', () {
      String maskEmail(String raw) {
        if (raw.isEmpty || !raw.contains('@')) return raw;
        final parts = raw.split('@');
        final username = parts[0];
        final domain = parts[1];
        if (username.length <= 2) {
          return '${username[0]}***@$domain';
        }
        return '${username[0]}***${username[username.length - 1]}@$domain';
      }

      expect(maskEmail('abrham@gmail.com'), 'a***m@gmail.com');
      expect(maskEmail('ed@yahoo.com'), 'e***@yahoo.com');
      expect(maskEmail('student.exam@matricet.edu.et'), 's***m@matricet.edu.et');
    });

    test('OTP token cleaning filters out non-digit characters and truncates to 6', () {
      String cleanOtp(String raw) {
        final cleaned = raw.replaceAll(RegExp(r'\D'), '');
        return cleaned.length > 6 ? cleaned.substring(0, 6) : cleaned;
      }

      expect(cleanOtp('123-456'), '123456');
      expect(cleanOtp('  987 654  '), '987654');
      expect(cleanOtp('Code: 584920!'), '584920');
      expect(cleanOtp('123456789'), '123456');
    });
  });
}
