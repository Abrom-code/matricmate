import 'package:firebase_auth/firebase_auth.dart';

class FirebaseAuthExceptions implements Exception {
  final String code;

  FirebaseAuthExceptions(this.code);

  factory FirebaseAuthExceptions.fromException(Exception e) {
    if (e is FirebaseAuthException) {
      return FirebaseAuthExceptions(e.code);
    }
    return FirebaseAuthExceptions('unknown');
  }

  String get message {
    switch (code) {
      case 'email-already-in-use':
      case 'account-exists-with-different-credential':
        return 'This email is already registered. Please log in or use a different email.';
      case 'invalid-email':
        return 'The email address is invalid. Please enter a valid email.';
      case 'weak-password':
        return 'The password is too weak. Please choose a stronger password.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Invalid email or password. Please check your credentials and try again.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'operation-not-allowed':
        return 'This sign-in method is currently disabled.';
      case 'invalid-verification-code':
        return 'The verification code is invalid. Please enter a valid code.';
      case 'invalid-verification-id':
        return 'The verification ID is invalid. Please request a new code.';
      case 'captcha-check-failed':
        return 'Security check failed. Please try again.';
      case 'quota-exceeded':
        return 'Daily limit reached. Please try again later.';
      case 'provider-already-linked':
        return 'This account is already linked with another provider.';
      case 'requires-recent-login':
        return 'For security, please log in again before making this change.';
      case 'credential-already-in-use':
        return 'This credential is already linked to another user.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      case 'internal-error':
        return 'A server error occurred. Please try again later.';
      default:
        return 'An authentication error occurred. Please try again.';
    }
  }
}
