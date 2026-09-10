import 'package:matricmate/utils/constants/app_timeouts.dart';
import 'package:matricmate/utils/exceptions/exception_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthenticationRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  User? get currentUser => _supabase.auth.currentUser;

  Stream<User?> get userChanges =>
      _supabase.auth.onAuthStateChange.map((state) => state.session?.user);

  Future<AuthResponse> registerWithEmailAndPassword(
    String email,
    String password, {
    Map<String, dynamic>? data,
  }) async {
    try {
      return await _supabase.auth.signUp(
        email: email,
        password: password,
        data: data,
      ).timeout(AppTimeouts.auth);
    } catch (e) {
      throw AppExceptionHandler.handle(e);
    }
  }

  Future<AuthResponse> loginUsingEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      return await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      ).timeout(AppTimeouts.auth);
    } catch (e) {
      throw AppExceptionHandler.handle(e);
    }
  }

  Future<void> sendEmailVerification() async {
    try {
      final email = _supabase.auth.currentUser?.email;
      if (email == null) return;
      await _supabase.auth.resend(
        type: OtpType.signup,
        email: email,
      ).timeout(AppTimeouts.auth);
    } catch (e) {
      throw AppExceptionHandler.handle(e);
    }
  }

  /// Requests a 6-digit recovery OTP for the given email via Supabase Auth.
  Future<void> sendPasswordResetOtp(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email).timeout(AppTimeouts.auth);
    } catch (e) {
      throw AppExceptionHandler.handle(e);
    }
  }

  /// Alias for backward compatibility.
  Future<void> sendResetPasswordEmail(String email) =>
      sendPasswordResetOtp(email);

  /// Verifies a 6-digit recovery OTP and establishes an authenticated recovery session.
  Future<AuthResponse> verifyPasswordResetOtp({
    required String email,
    required String token,
  }) async {
    try {
      return await _supabase.auth.verifyOTP(
        email: email,
        token: token,
        type: OtpType.recovery,
      ).timeout(AppTimeouts.auth);
    } catch (e) {
      throw AppExceptionHandler.handle(e);
    }
  }

  /// Updates the user's password using the established recovery session.
  Future<UserResponse> updatePassword(String password) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw 'No authenticated user found';

      return await _supabase.auth.updateUser(
        UserAttributes(password: password),
      ).timeout(AppTimeouts.auth);
    } catch (e) {
      throw AppExceptionHandler.handle(e);
    }
  }

  /// Alias for backward compatibility.
  Future<void> updateUserPassword(String newPassword) =>
      updatePassword(newPassword);

  Future<void> reAuthenticate(String email, String password) async {
    try {
      await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      ).timeout(AppTimeouts.auth);
    } catch (e) {
      throw AppExceptionHandler.handle(e);
    }
  }

  Future<void> logout() async {
    try {
      await _supabase.auth.signOut().timeout(const Duration(seconds: 3));
    } catch (e) {
      // Best-effort remote sign out; local clearing should proceed even if offline
    }
  }

  Future<void> deleteAccount() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw 'No authenticated user';

      await _supabase.rpc('delete_own_account').timeout(AppTimeouts.delete);
      try {
        await _supabase.auth.signOut().timeout(AppTimeouts.bestEffort);
      } catch (_) {}
    } catch (e) {
      throw AppExceptionHandler.handle(e);
    }
  }

  Future<void> reloadUser() async {
    try {
      await _supabase.auth.getUser().timeout(AppTimeouts.auth);
    } catch (e) {
      throw AppExceptionHandler.handle(e);
    }
  }
}
