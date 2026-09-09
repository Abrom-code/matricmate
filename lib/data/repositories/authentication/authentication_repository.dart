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
      );
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
      );
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
      );
    } catch (e) {
      throw AppExceptionHandler.handle(e);
    }
  }

  Future<void> sendResetPasswordEmail(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
    } catch (e) {
      throw AppExceptionHandler.handle(e);
    }
  }

  Future<void> updateUserPassword(String newPassword) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw 'No authenticated user found';

      await _supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );
    } catch (e) {
      throw AppExceptionHandler.handle(e);
    }
  }

  Future<void> reAuthenticate(String email, String password) async {
    try {
      await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      throw AppExceptionHandler.handle(e);
    }
  }

  Future<void> logout() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      throw AppExceptionHandler.handle(e);
    }
  }

  Future<void> deleteAccount() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw 'No authenticated user';

      await _supabase.rpc('delete_own_account');
      try {
        await _supabase.auth.signOut();
      } catch (_) {}
    } catch (e) {
      throw AppExceptionHandler.handle(e);
    }
  }

  Future<void> reloadUser() async {
    try {
      await _supabase.auth.getUser();
    } catch (e) {
      throw AppExceptionHandler.handle(e);
    }
  }
}
