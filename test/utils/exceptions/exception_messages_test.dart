import 'package:flutter_test/flutter_test.dart';
import 'package:matricmate/utils/exceptions/exception_handler.dart';
import 'package:matricmate/utils/exceptions/firebase_exceptions.dart';
import 'package:matricmate/utils/exceptions/format_exceptions.dart';
import 'package:matricmate/utils/exceptions/platform_exceptions.dart';
import 'package:matricmate/utils/exceptions/sqflite_exceptions.dart';
import 'package:matricmate/utils/exceptions/supabase_exception.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('Authentication and data error messages', () {
    test('maps common authentication failures', () {
      final authFailure = AppExceptionHandler.handle(
        const AuthException('Invalid login credentials'),
      );
      expect(
        authFailure.message,
        contains('Invalid credentials'),
      );
      expect(
        AppExceptionHandler.handle(const AuthException('User already registered')).message,
        contains('already exists'),
      );
      expect(
        AppExceptionHandler.handle(const AuthException('Email not confirmed')).message,
        contains('not been confirmed'),
      );
      expect(
        AppExceptionHandler.handle(const AuthException('Password should be at least 6 characters')).message,
        contains('at least 6 characters'),
      );
      expect(
        AppExceptionHandler.handle(const AuthException('For security purposes, you can only request this once every 60 seconds')).message,
        contains('Too many attempts'),
      );
      expect(
        AppExceptionHandler.handle(const AuthException('Token has expired or is invalid')).message,
        contains('expired'),
      );
      expect(
        AppExceptionHandler.handle(const AuthException('User not found')).message,
        contains('No account found'),
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
      final unknownAuthFailure = AppExceptionHandler.handle(
        const AuthException('Some random auth failure'),
      );
      expect(
        unknownAuthFailure.message,
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
