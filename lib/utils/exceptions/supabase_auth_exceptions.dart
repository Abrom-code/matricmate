import 'package:matricmate/utils/exceptions/app_failure_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Exception class for handling Supabase Authentication errors with
/// user-friendly messages for registration, login, verification, and recovery.
class SupabaseAuthExceptions implements Exception {
  final String? code;
  final String message;
  final String? statusCode;

  const SupabaseAuthExceptions(
    this.message, {
    this.code,
    this.statusCode,
  });

  factory SupabaseAuthExceptions.fromException(AuthException e) {
    return SupabaseAuthExceptions(
      e.message,
      code: e.code,
      statusCode: e.statusCode,
    );
  }

  AppFailure toFailure() {
    final lowerMsg = message.toLowerCase();
    final lowerCode = (code ?? '').toLowerCase();

    // 1. Invalid Credentials / Wrong Password
    if (lowerCode == 'invalid_credentials' ||
        lowerMsg.contains('invalid login credentials') ||
        lowerMsg.contains('invalid credentials') ||
        lowerMsg.contains('wrong password') ||
        lowerMsg.contains('invalid password')) {
      return const AppFailure(
        title: 'Invalid Credentials',
        message: 'Invalid credentials. Incorrect email or password. Please verify your details and try again.',
        code: 'invalid_credentials',
      );
    }

    // 2. User / Email Already Registered
    if (lowerCode == 'user_already_exists' ||
        lowerCode == 'email_exists' ||
        lowerMsg.contains('user already registered') ||
        lowerMsg.contains('already registered') ||
        lowerMsg.contains('already in use') ||
        lowerMsg.contains('email already exists')) {
      return const AppFailure(
        title: 'Account Already Exists',
        message: 'An account with this email address already exists. Please log in or reset your password.',
        code: 'user_already_exists',
      );
    }

    // 3. Email Not Confirmed
    if (lowerCode == 'email_not_confirmed' ||
        lowerMsg.contains('email not confirmed') ||
        lowerMsg.contains('unconfirmed email')) {
      return const AppFailure(
        title: 'Email Not Confirmed',
        message: 'Your email address has not been confirmed yet. Please check your inbox for the confirmation link.',
        code: 'email_not_confirmed',
      );
    }

    // 4. Password Too Weak / Short
    if (lowerCode == 'weak_password' ||
        lowerMsg.contains('password should be at least') ||
        lowerMsg.contains('weak password') ||
        lowerMsg.contains('password is too short')) {
      return const AppFailure(
        title: 'Weak Password',
        message: 'Password must be at least 6 characters long.',
        code: 'weak_password',
      );
    }

    // 5. Rate Limit / Too Many Attempts
    if (lowerCode == 'over_request_rate_limit' ||
        lowerCode == 'over_email_send_rate_limit' ||
        lowerCode == 'too_many_requests' ||
        lowerMsg.contains('rate limit') ||
        lowerMsg.contains('too many requests') ||
        lowerMsg.contains('for security purposes') ||
        statusCode == '429') {
      return const AppFailure(
        title: 'Too Many Attempts',
        message: 'Too many attempts in a short time. Please wait a moment before trying again.',
        code: 'rate_limit',
      );
    }

    // 6. Token / OTP Expired or Invalid
    if (lowerCode == 'otp_expired' ||
        lowerCode == 'bad_jwt' ||
        lowerMsg.contains('token has expired') ||
        lowerMsg.contains('is invalid or has expired') ||
        lowerMsg.contains('token is expired') ||
        lowerMsg.contains('invalid token') ||
        lowerMsg.contains('otp is invalid')) {
      return const AppFailure(
        title: 'Code Expired or Invalid',
        message: 'The verification code or link is invalid or has expired. Please request a new one.',
        code: 'token_expired',
      );
    }

    // 7. Session Expired / Token Refresh Failed
    if (lowerCode == 'session_not_found' ||
        lowerCode == 'refresh_token_not_found' ||
        lowerMsg.contains('session expired') ||
        lowerMsg.contains('jwt expired') ||
        lowerMsg.contains('session from sub claim')) {
      return const AppFailure(
        title: 'Session Expired',
        message: 'Your session has expired. Please log in again.',
        code: 'session_expired',
      );
    }

    // 8. User Not Found
    if (lowerCode == 'user_not_found' ||
        lowerMsg.contains('user not found') ||
        lowerMsg.contains('no user found')) {
      return const AppFailure(
        title: 'Account Not Found',
        message: 'No account found with this email address.',
        code: 'user_not_found',
      );
    }

    // 9. Same Password
    if (lowerCode == 'same_password' ||
        lowerMsg.contains('different from the old') ||
        lowerMsg.contains('same password')) {
      return const AppFailure(
        title: 'Same Password',
        message: 'Your new password must be different from your old password.',
        code: 'same_password',
      );
    }

    // 10. Invalid Email Format
    if (lowerCode == 'validation_failed' ||
        lowerMsg.contains('invalid email') ||
        lowerMsg.contains('unable to validate email')) {
      return const AppFailure(
        title: 'Invalid Email',
        message: 'Please enter a valid email address.',
        code: 'invalid_email',
      );
    }

    // 11. Signup Disabled
    if (lowerCode == 'signup_disabled' ||
        lowerMsg.contains('signups not allowed') ||
        lowerMsg.contains('signup is disabled')) {
      return const AppFailure(
        title: 'Signups Disabled',
        message: 'Registration is currently disabled. Please contact support.',
        code: 'signup_disabled',
      );
    }

    // 12. Fallback for unknown AuthException
    return const AppFailure(
      title: 'Authentication Error',
      message: 'An authentication error occurred. Please try again.',
    );
  }
}
