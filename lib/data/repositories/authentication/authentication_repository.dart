import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:matricmate/features/authentication/screens/login/login.dart';
import 'package:matricmate/features/authentication/screens/signup/verify_email.dart';
import 'package:matricmate/navigation_menu.dart';
import 'package:matricmate/utils/exceptions/firebase_auth_exceptions.dart';
import 'package:matricmate/utils/exceptions/firebase_exceptions.dart';
import 'package:matricmate/utils/exceptions/format_exceptions.dart';

class AuthenticationRepository extends GetxController {
  static AuthenticationRepository get instance => Get.find();

  final _deviceStorage = GetStorage();
  final _auth = FirebaseAuth.instance;
  late final Rx<User?> firebaseUser;

  User? get authUser => _auth.currentUser;

  @override
  void onReady() {
    // Remove splash screen
    FlutterNativeSplash.remove();

    // Initialize user stream and bind to the redirection logic
    firebaseUser = Rx<User?>(_auth.currentUser);
    firebaseUser.bindStream(_auth.userChanges());

    screenRedirect();
  }

  /// Decide where to send the user based on Auth state
  void screenRedirect() {
    final user = _auth.currentUser;
    if (user != null) {
      // User is Logged In
      if (user.emailVerified) {
        Get.offAll(() => const NavigationMenu());
      } else {
        Get.offAll(() => VerifyEmailScreen(email: _auth.currentUser?.email));
      }
    } else {
      // User is Logged Out
      _deviceStorage.writeIfNull('isFirstTime', true);
      Get.offAll(() => const LoginScreen());
    }
  }

  /// Register
  Future<UserCredential> registerWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw FirebaseAuthExceptions(e.code).message;
    } on FirebaseException catch (e) {
      throw FirebaseExceptions(e.code).message;
    } on FormatException catch (_) {
      throw const FormatExceptions().message;
    } on Exception catch (e) {
      throw e.toString();
    }
  }

  /// Email Verification
  Future<void> sendEmailVerification() async {
    try {
      await _auth.currentUser?.sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      throw FirebaseAuthExceptions(e.code).message;
    } on FirebaseException catch (e) {
      throw FirebaseExceptions(e.code).message;
    } catch (_) {
      throw 'Something went wrong. Please try again';
    }
  }

  // Hande signin using login and password
  Future<UserCredential> loginUsingEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw FirebaseAuthExceptions(e.code).message;
    } on FirebaseException catch (e) {
      throw FirebaseExceptions(e.code).message;
    } on FormatException catch (_) {
      throw const FormatExceptions().message;
    } on Exception catch (e) {
      throw e.toString();
    }
  }

  // update password
  Future<void> updateUserPassword(String newPassword) async {
    try {
      final user = _auth.currentUser;

      if (user == null) {
        throw 'No authenticated user found';
      }

      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw FirebaseAuthExceptions(e.code).message;
    } on FirebaseException catch (e) {
      throw FirebaseExceptions(e.code).message;
    } on FormatException catch (_) {
      throw const FormatExceptions().message;
    } on Exception catch (e) {
      throw e.toString();
    }
  }

  /// Handle logout
  Future<void> logout() async {
    try {
      await _auth.signOut();
      Get.offAll(() => const LoginScreen());
    } on FirebaseAuthException catch (e) {
      throw FirebaseAuthExceptions(e.code).message;
    } on FirebaseException catch (e) {
      throw FirebaseExceptions(e.code).message;
    } on FormatException catch (_) {
      throw const FormatExceptions().message;
    } on Exception {
      throw 'Something went wrong. Please try again';
    }
  }

  Future<void> sendResetPasswordEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw FirebaseAuthExceptions(e.code).message;
    } on FirebaseException catch (e) {
      throw FirebaseExceptions(e.code).message;
    } on FormatException catch (_) {
      throw const FormatExceptions().message;
    } on Exception {
      throw 'Something went wrong. Please try again';
    }
  }
}
