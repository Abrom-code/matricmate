import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:get/get_core/src/get_main.dart' show Get;
import 'package:get/get_instance/src/extension_instance.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:get/get_state_manager/src/simple/get_controllers.dart';
import 'package:get_storage/get_storage.dart';
import 'package:matricmate/data/database/database_service.dart';
import 'package:matricmate/data/repositories/authentication/authentication_repository.dart';
import 'package:matricmate/data/repositories/user/user_repository.dart';
import 'package:matricmate/features/exam/controllers/subjects_controller.dart';
import 'package:matricmate/features/personalization/controller/user_controller.dart';
import 'package:matricmate/routes/app_routes.dart';
import 'package:matricmate/utils/exceptions/exeption_handler.dart';
import 'package:matricmate/utils/network_manager/network_manager.dart';

class AuthenticationController extends GetxController {
  static AuthenticationController get instance => Get.find();

  final authRepo = Get.find<AuthenticationRepository>();
  final userRepo = Get.find<UserRepository>();
  final deviceStorage = GetStorage();

  late Rx<User?> firebaseUser;

  @override
  void onReady() {
    firebaseUser = Rx<User?>(authRepo.currentUser);
    firebaseUser.bindStream(authRepo.userChanges);

    screenRedirect();
  }

  Future<void> screenRedirect() async {
    final user = authRepo.currentUser;

    if (user == null) {
      Get.offAllNamed(Routes.signIn);
      FlutterNativeSplash.remove();
      return;
    }

    if (!user.emailVerified) {
      Get.offAllNamed(Routes.verifyEmail, arguments: {'email': user.email});
      FlutterNativeSplash.remove();
      return;
    }

    await UserController.instance.loadLocalUser();
    await SubjectsController.instance.loadLocalSubjects();

    Get.offAllNamed(Routes.navigationMenu);

    final hasInternet = await NetworkManager.instance.hasRealInternet();

    if (hasInternet) {
      Future(() async {
        try {
          await UserController.instance.fetchUserRecord();
        } catch (_) {}
      });
    }
    FlutterNativeSplash.remove();
  }

  Future<void> logout() async {
    try {
      await userRepo.deleteUserRecord(authRepo.currentUser!.uid);

      await authRepo.logout();

      Get.offAllNamed(Routes.signIn);
    } catch (e) {
      throw AppExceptionHandler.handle(e);
    }
  }

  Future<void> deleteAccount(String password) async {
    try {
      final user = authRepo.currentUser;
      if (user == null) throw 'No user';

      // re-auth
      await authRepo.reAuthenticate(user.email!, password);

      // delete backend data
      await userRepo.deleteUserRecord(user.uid);

      // clear local
      await DatabaseService.instance.clearAllData();
      await deviceStorage.erase();

      // delete firebase
      await authRepo.deleteFirebaseAccount();

      Get.offAllNamed(Routes.signIn);
    } catch (e) {
      throw AppExceptionHandler.handle(e);
    }
  }
}
