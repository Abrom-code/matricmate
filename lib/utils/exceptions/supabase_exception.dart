import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseDbExceptions implements Exception {
  final String code;
  final String? customMessage;

  SupabaseDbExceptions(this.code, {this.customMessage});

  factory SupabaseDbExceptions.fromException(Object e) {
    if (e is PostgrestException) {
      return SupabaseDbExceptions(e.code ?? 'unknown', customMessage: e.message);
    }
    return SupabaseDbExceptions('unknown');
  }

  String get message {
    if (customMessage != null && customMessage!.isNotEmpty) {
      final msg = customMessage!.toLowerCase();
      if (msg.contains('challenge_not_started') || msg.contains('not_open_yet')) {
        return 'This challenge has not started yet. Please check the scheduled start time.';
      }
      if (msg.contains('challenge_ended') || msg.contains('challenge_closed') || msg.contains('challenge_not_active')) {
        return 'This challenge has ended or is no longer active.';
      }
      if (msg.contains('already_submitted')) {
        return 'You have already submitted your attempt for this challenge.';
      }
      if (msg.contains('premium_required')) {
        return 'A premium subscription is required to participate in challenges.';
      }
      if (msg.contains('stream_not_eligible') || msg.contains('audience_mismatch')) {
        return 'This challenge is not open to your stream.';
      }
      if (msg.contains('challenge_not_found')) {
        return 'Challenge not found or has been removed.';
      }
      if (msg.contains('user_not_found')) {
        return 'User account not found. Please log in again.';
      }
      if (msg.contains('invalid_or_completed_attempt')) {
        return 'This challenge attempt is already completed or invalid.';
      }
    }

    switch (code) {
      // --- Integrity & Constraints ---
      case '23505':
        return 'This record already exists.';
      case '23503':
        return 'This action cannot be completed because it is linked to another record.';
      case '23502':
        return 'A required field is missing. Please fill in all necessary info.';
      case '23514':
        return 'The information provided does not meet the required format.';

      // --- Permissions & Security ---
      case '42501':
        return 'You do not have permission to perform this action.';

      // --- API & Request Errors (PGRST) ---
      case 'PGRST116':
        return 'Could not find the requested information.';
      case 'PGRST100':
        return 'The search filter is invalid. Please check your query.';
      case 'PGRST102':
        return 'The data sent was malformed. Please try again.';
      case 'PGRST301':
        return 'Your session has expired. Please log in again.';

      // --- Database/Table Issues ---
      case '42P01':
        return 'The requested resource could not be found on the server.';
      case '42703':
        return 'One of the data fields is invalid or missing.';

      // --- Connection & Server ---
      case '08001':
      case '08006':
      case 'PGRST000':
        return 'Connection error. Please check your internet and try again.';
      case '57014':
        return 'The request took too long and was cancelled.';

      default:
        return 'A database error occurred. Please try again later.';
    }
  }
}
