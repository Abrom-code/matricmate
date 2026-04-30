import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:matricmate/utils/helpers/toast_helper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_failure_model.dart';
import 'firebase_auth_exceptions.dart';
import 'firebase_exceptions.dart';
import 'format_exceptions.dart';
import 'platform_exceptions.dart';
import 'sqflite_expcetions.dart';
import 'supabase_exception.dart';

class AppExceptionHandler {
  AppExceptionHandler._();
  static void handleResponse(dynamic e) {
    if (e is AppFailure) {
      ToastHelper.error(e.title, e.message);
    } else {
      ToastHelper.error("Unexpected Error", e.toString());
    }
  }

  static AppFailure handle(Object e) {
    if (e is AppFailure) {
      return e;
    }
    // Firebase Auth
    if (e is FirebaseAuthException) {
      return AppFailure(
        title: "Authentication Error",
        message: FirebaseAuthExceptions.fromException(e).message,
        code: e.code,
      );
    }

    // Firebase general
    if (e is FirebaseException) {
      return AppFailure(
        title: "Firebase Error",
        message: FirebaseExceptions(e.code).message,
        code: e.code,
      );
    }

    // Supabase database
    if (e is PostgrestException) {
      final supa = SupabaseDbExceptions.fromException(e);
      return AppFailure(
        title: "Database Error",
        message: supa.message,
        code: e.code,
      );
    }

    // SQLite
    if (e.toString().contains('DatabaseException')) {
      final sqf = SqfliteDbExceptions.fromException(e);
      return AppFailure(title: "Local Database Error", message: sqf.message);
    }

    // Format errors
    if (e is FormatException) {
      return AppFailure(
        title: "Format Error",
        message: const FormatExceptions().formattedMessage,
      );
    }

    // Platform exceptions
    if (e is PlatformException) {
      return AppFailure(
        title: "Platform Error",
        message: PlatformExceptions(e.code).message,
        code: e.code,
      );
    }

    // Network errors
    if (e is SocketException) {
      return AppFailure(
        title: "Connection Error",
        message: "No internet connection or connection was interrupted",
      );
    }

    // Fallback
    return AppFailure(
      title: "Unexpected Error",
      message: "Something went wrong. Please try again.",
    );
  }
}
