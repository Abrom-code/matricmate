import 'package:firebase_auth/firebase_auth.dart';
import 'package:matricmate/utils/exceptions/exeption_handler.dart';

class AuthenticationRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

  Stream<User?> get userChanges => _auth.userChanges();

  Future<UserCredential> registerWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      throw AppExceptionHandler.handle(e);
    }
  }

  Future<UserCredential> loginUsingEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      throw AppExceptionHandler.handle(e);
    }
  }

  Future<void> sendEmailVerification() async {
    try {
      await _auth.currentUser?.sendEmailVerification();
    } catch (e) {
      throw AppExceptionHandler.handle(e);
    }
  }

  Future<void> sendResetPasswordEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw AppExceptionHandler.handle(e);
    }
  }

  Future<void> updateUserPassword(String newPassword) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw 'No authenticated user found';

      await user.updatePassword(newPassword);
    } catch (e) {
      throw AppExceptionHandler.handle(e);
    }
  }

  Future<void> reAuthenticate(String email, String password) async {
    try {
      final credential = EmailAuthProvider.credential(
        email: email,
        password: password,
      );

      await _auth.currentUser!.reauthenticateWithCredential(credential);
    } catch (e) {
      throw AppExceptionHandler.handle(e);
    }
  }

  Future<void> logout() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw AppExceptionHandler.handle(e);
    }
  }

  Future<void> deleteFirebaseAccount() async {
    final user = _auth.currentUser;
    if (user == null) throw 'No authenticated user';

    await user.delete();
  }

  Future<void> reloadUser() async {
    await _auth.currentUser?.reload();
  }
}
