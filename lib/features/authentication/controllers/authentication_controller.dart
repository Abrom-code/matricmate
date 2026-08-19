import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:matricmate/data/database/database_service.dart';
import 'package:matricmate/data/repositories/authentication/authentication_repository.dart';
import 'package:matricmate/data/repositories/user/user_repository.dart';
import 'package:matricmate/data/services/fcm_service.dart';
import 'package:matricmate/data/services/payment_config_service.dart';
import 'package:matricmate/data/services/realtime_service.dart';
import 'package:matricmate/features/exam/controllers/subjects_controller.dart';
import 'package:matricmate/features/exam/controllers/syncing_controller.dart';
import 'package:matricmate/features/notifications/controllers/notifications_controller.dart';
import 'package:matricmate/features/personalization/controllers/user_controller.dart';
import 'package:matricmate/routes/app_routes.dart';
import 'package:matricmate/utils/exceptions/exception_handler.dart';
import 'package:matricmate/utils/constants/app_timeouts.dart';
import 'package:matricmate/utils/network_manager/network_manager.dart';

/// GetStorage key that records the last time session validation ran.
const _kLastSessionCheckKey = 'last_session_check_ms';

/// Minimum gap between periodic session checks (12 hours).
const _kSessionCheckInterval = Duration(hours: 12);

class AuthenticationController extends GetxController
    with WidgetsBindingObserver {
  static AuthenticationController get instance => Get.find();

  final authRepo = Get.find<AuthenticationRepository>();
  final userRepo = Get.find<UserRepository>();
  final deviceStorage = GetStorage();

  late Rx<User?> firebaseUser;

  /// True while the loading screen is doing initial data fetch.
  final RxBool isInitializing = false.obs;
  final RxString initStatus = 'Getting things ready…'.obs;

  @override
  void onReady() {
    WidgetsBinding.instance.addObserver(this);
    firebaseUser = Rx<User?>(authRepo.currentUser);
    firebaseUser.bindStream(authRepo.userChanges);
    _init();
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  /// Runs session check on app resume if 12h have elapsed.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_periodicSessionCheck());
    }
  }

  /// Pre-loads local data then navigates to the appropriate screen.
  Future<void> _init() async {
    try {
      final user = authRepo.currentUser;
      if (user != null && user.emailVerified) {
        // Load user record before screenRedirect decides navigation
        await UserController.instance.loadLocalUser();
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

    // Navigate to loading screen for init splash
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

    bool networkFetchSucceeded = false;

    try {
      isInitializing.value = true;

      final isConnected = await NetworkManager.instance.isConnected();

      // Step 1 — fetch user record (validates session and premium status)
      if (isConnected) {
        try {
          initStatus.value = 'Verifying account…';
          final fetched = await UserController.instance
              .fetchUserRecord()
              .timeout(AppTimeouts.verify);
          if (fetched) {
            await UserController.instance.loadLocalUser();
            networkFetchSucceeded = true;
          } else {
            // fetchUserRecord returned false — fall back to local cache
            await UserController.instance.loadLocalUser();
          }
        } catch (_) {
          // Connection dropped mid-verify — fall back to local
          await UserController.instance.loadLocalUser();
        }
      }

      // Step 2 — load subjects from local DB (always runs regardless of network)
      initStatus.value = 'Loading subjects…';
      await SubjectsController.instance.loadLocalSubjects();

      if (isConnected && networkFetchSucceeded) {
        // Step 3 — first login with no local subjects: fetch from remote
        if (SubjectsController.instance.subjects.isEmpty) {
          try {
            await SubjectsController.instance.initFromRemote().timeout(
              AppTimeouts.initFromRemote,
            );
          } catch (_) {
            // Timed out or failed — subjects remain empty; user can retry later.
          }
        }
        // Refresh entrance counts from remote
        try {
          initStatus.value = 'Loading exam info…';
          await SubjectsController.instance
              .refreshEntranceCountsFromRemote()
              .timeout(AppTimeouts.entranceCounts);
        } catch (_) {
          // Timed out or failed — cached counts still shown.
        }
      } else if (isConnected && !networkFetchSucceeded) {
        // Partial connectivity: attempt best-effort remote fetch
        if (SubjectsController.instance.subjects.isEmpty) {
          try {
            await SubjectsController.instance.initFromRemote().timeout(
              AppTimeouts.initFromRemote,
            );
            // Reload after remote fetch so subjects list is populated.
            await SubjectsController.instance.loadLocalSubjects();
          } catch (_) {
            // Timed out or failed — navigate with whatever we have.
          }
        }
      }

      initStatus.value = 'Almost done…';
    } catch (_) {
      // Safety net: ensure subjects are loaded before navigating
      try {
        await SubjectsController.instance.loadLocalSubjects();
      } catch (_) {}
    } finally {
      isInitializing.value = false;
    }

    // Navigate to home — all subject/user data is ready at this point.
    Get.offAllNamed(Routes.navigationMenu);

    // Background: entrance counts, delta sync, realtime (non-blocking)
    unawaited(_backgroundRefresh());
  }

  /// Runs after navigation — never blocks the UI.
  Future<void> _backgroundRefresh() async {
    try {
      final isConnected = await NetworkManager.instance.isConnected();
      if (!isConnected) return;

      // Delta sync — picks up any new tests/questions since last sync
      unawaited(SyncingController.instance.syncAll(showUiLoading: false));

      // Start Realtime
      final uid = authRepo.currentUser?.uid ?? '';
      final downloadedIds = SubjectsController.instance.subjects
          .where((s) => s.isDownloaded || s.isEntranceDownloaded)
          .map((s) => s.id)
          .toList();
      unawaited(RealtimeService.instance.start(downloadedIds, userId: uid));

      // Load payment config with auth (RLS-protected)
      unawaited(PaymentConfigService.instance.load());

      // Load notifications in background
      unawaited(
        NotificationsController.instance.loadNotifications(syncRemote: true),
      );

      // Initialise FCM after UserController.user is populated
      unawaited(FcmService.instance.init());

      // Periodic session check (12h gap)
      await _periodicSessionCheck();
    } catch (e) {
      AppExceptionHandler.handleResponse(e);
    }
  }

  /// Validates session at most once every 12 hours. Triggers logout if device unauthorized.
  Future<void> _periodicSessionCheck() async {
    try {
      // Must be logged in
      if (authRepo.currentUser == null) return;

      // Check interval
      final lastMs = deviceStorage.read<int>(_kLastSessionCheckKey);
      final now = DateTime.now().millisecondsSinceEpoch;
      if (lastMs != null &&
          now - lastMs < _kSessionCheckInterval.inMilliseconds) {
        return; // Too soon — skip
      }

      // Need internet
      final isConnected = await NetworkManager.instance.isConnected();
      if (!isConnected) return;

      // Run the check — fetchUserRecord handles device-mismatch logout
      final ok = await UserController.instance.fetchUserRecord();

      // Only update timestamp on success
      if (ok) {
        deviceStorage.write(_kLastSessionCheckKey, now);
      }
    } catch (_) {
      // Non-fatal — never interrupt user for background check failure
    }
  }

  Future<void> logout() async {
    try {
      _initStarted = false;
      deviceStorage.remove(_kLastSessionCheckKey);
      await Future.wait([
        authRepo.logout(),
        SyncingController.instance.clearSyncTimestamps(),
        RealtimeService.instance.stop(),
        FcmService.instance.unsubscribeAll(), // unregister topics on sign-out
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
