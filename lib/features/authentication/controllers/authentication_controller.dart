import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:matricmate/data/database/database_service.dart';
import 'package:matricmate/data/repositories/authentication/authentication_repository.dart';
import 'package:matricmate/data/repositories/user/user_repository.dart';
import 'package:matricmate/data/services/realtime_service.dart';
import 'package:matricmate/features/exam/controllers/subjects_controller.dart';
import 'package:matricmate/features/exam/controllers/syncing_controller.dart';
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

  /// True while the loading screen is doing initial data fetch.
  /// The LoadingScreen watches this and auto-navigates when it turns false.
  final RxBool isInitializing = false.obs;
  final RxString initStatus = 'Getting things ready…'.obs;

  @override
  void onReady() {
    firebaseUser = Rx<User?>(authRepo.currentUser);
    firebaseUser.bindStream(authRepo.userChanges);
    _init();
  }

  /// Pre-loads local data then navigates to the appropriate screen.
  /// Only reads from SQLite — no network calls here, so it's instant.
  Future<void> _init() async {
    try {
      final user = authRepo.currentUser;
      if (user != null && user.emailVerified) {
        await Future.wait([
          UserController.instance.loadLocalUser(),
          SubjectsController.instance.loadLocalSubjects(),
        ]);
      }
    } catch (_) {}
    screenRedirect();
  }

  Future<void> screenRedirect() async {
    final user = authRepo.currentUser;

    if (user == null) {
      Get.offAllNamed(Routes.signIn);
      return;
    }

    if (!user.emailVerified) {
      Get.offAllNamed(Routes.verifyEmail, arguments: {'email': user.email});
      return;
    }

    // Reset so _runInitThenNavigate always runs fresh on each login.
    _initStarted = false;

    // If we're not already on the loading screen, navigate there first
    // so the splash is visible during init.
    final currentRoute = Get.currentRoute;
    if (currentRoute != Routes.loading) {
      Get.offAllNamed(Routes.loading);
    }

    await _runInitThenNavigate();
  }

  bool _initStarted = false;

  /// Runs on the loading screen — fetches minimum data then goes to home.
  Future<void> _runInitThenNavigate() async {
    if (_initStarted) return;
    _initStarted = true;

    try {
      isInitializing.value = true;

      final isConnected = await NetworkManager.instance.isConnected();

      // Step 1 — fetch user record (validates session, gets premium status)
      if (isConnected) {
        initStatus.value = 'Verifying account…';
        await UserController.instance.fetchUserRecord();
        await UserController.instance.loadLocalUser();
      }

      // Step 2 — load subjects (local first, remote if empty)
      final hasSubjects = SubjectsController.instance.subjects.isNotEmpty;
      if (!hasSubjects && isConnected) {
        initStatus.value = 'Loading subjects…';
        await SubjectsController.instance.initFromRemote();
      }

      initStatus.value = 'Almost done…';
    } catch (_) {
      // Non-fatal — always navigate
    } finally {
      isInitializing.value = false;
    }

    // Navigate to home
    Get.offAllNamed(Routes.navigationMenu);

    // Background: full delta sync + realtime (non-blocking)
    unawaited(_backgroundRefresh());
  }

  /// Runs after navigation — never blocks the UI.
  Future<void> _backgroundRefresh() async {
    try {
      final isConnected = await NetworkManager.instance.isConnected();
      if (!isConnected) return;

      // Delta sync — picks up any new tests/questions since last sync
      unawaited(SyncingController.instance.syncAll());

      // Start Realtime: user status channel (always) + question edits
      // scoped to downloaded subjects only.
      final uid = authRepo.currentUser?.uid ?? '';
      final downloadedIds = SubjectsController.instance.subjects
          .where((s) => s.isDownloaded || s.isEntranceDownloaded)
          .map((s) => s.id)
          .toList();
      unawaited(RealtimeService.instance.start(downloadedIds, userId: uid));
    } catch (e) {
      AppExceptionHandler.handleResponse(e);
    }
  }

  Future<void> logout() async {
    try {
      _initStarted = false;
      await Future.wait([
        authRepo.logout(),
        SyncingController.instance.clearSyncTimestamps(),
        RealtimeService.instance.stop(),
      ]);
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
      await Future.wait([
        DatabaseService.instance.clearAllData(),
        SyncingController.instance.clearSyncTimestamps(),
      ]);
      await deviceStorage.erase();

      // delete firebase
      await authRepo.deleteFirebaseAccount();

      Get.offAllNamed(Routes.signIn);
    } catch (e) {
      throw AppExceptionHandler.handle(e);
    }
  }
}
