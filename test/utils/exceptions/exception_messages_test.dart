import 'package:flutter_test/flutter_test.dart';
import 'package:matricmate/utils/exceptions/firebase_auth_exceptions.dart';
import 'package:matricmate/utils/exceptions/firebase_exceptions.dart';
import 'package:matricmate/utils/exceptions/format_exceptions.dart';
import 'package:matricmate/utils/exceptions/platform_exceptions.dart';
import 'package:matricmate/utils/exceptions/sqflite_expcetions.dart';
import 'package:matricmate/utils/exceptions/supabase_exception.dart';

void main() {
  group('Authentication and data error messages', () {
    test('maps common Firebase authentication failures', () {
      expect(
        FirebaseAuthExceptions('wrong-password').message,
        contains('Invalid email or password'),
      );
      expect(
        FirebaseExceptions('invalid-email').message,
        contains('email address'),
      );
      expect(
        PlatformExceptions('network-request-failed').message,
        contains('internet connection'),
      );
    });

    test('maps known Supabase and SQLite failures', () {
      expect(
        SupabaseDbExceptions('23505').message,
        'This record already exists.',
      );
      expect(
        SqfliteDbExceptions.fromException(
          Exception('DatabaseException: no such table: tests'),
        ).message,
        'Database not initialized properly.',
      );
    });

    test('uses a safe fallback for unknown exceptions and format codes', () {
      expect(
        FirebaseAuthExceptions('not-known').message,
        'An authentication error occurred. Please try again.',
      );
      expect(
        FormatExceptions.fromCode('invalid-url-format').formattedMessage,
        contains('URL format'),
      );
      expect(
        FormatExceptions.fromCode('not-known').formattedMessage,
        contains('unexpected format error'),
      );
    });
  });
}
