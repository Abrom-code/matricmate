import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:matricmate/data/database/database_service.dart';
import 'package:matricmate/data/repositories/authentication/authentication_repository.dart';
import 'package:matricmate/data/repositories/user/user_repository.dart';
import 'package:matricmate/data/services/realtime_service.dart';
import 'package:matricmate/features/exam/controllers/subjects_controller.dart';
import 'package:matricmate/features/exam/controllers/syncing_controller.dart';
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

  /// Fires when the app returns to the foreground.
  /// Runs a session check if 12 h have elapsed and network is available.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_periodicSessionCheck());
    }
  }

  /// Pre-loads local data then navigates to the appropriate screen.
  /// Only reads from SQLite — no network calls here, so it's instant.
  Future<void> _init() async {
    try {
      final user = authRepo.currentUser;
      if (user != null && user.emailVerified) {
        // Load user record so UserController.user is populated before
        // screenRedirect() decides where to navigate.
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

    bool networkFetchSucceeded = false;

    try {
      isInitializing.value = true;

      final isConnected = await NetworkManager.instance.isConnected();

      // Step 1 — fetch user record (validates session, gets premium status).
      // Wrapped independently so a mid-fetch connection drop cannot skip the
      // local-subject load below (Step 2).
      // Times out after _kVerifyTimeout — if the server is slow we don't
      // block the user on the splash forever.
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
            // fetchUserRecord returned false (e.g. session blocked) — fall
            // back to whatever is cached locally.
            await UserController.instance.loadLocalUser();
          }
        } catch (_) {
          // Connection dropped or timed out mid-verify — fall back to local
          // user record and continue.
          await UserController.instance.loadLocalUser();
        }
      }

      // Step 2 — load subjects from local DB.
      // This MUST always run regardless of network outcome so the subjects
      // screen never renders with an empty list after a mid-fetch dropout.
      initStatus.value = 'Loading subjects…';
      await SubjectsController.instance.loadLocalSubjects();

      if (isConnected && networkFetchSucceeded) {
        // Step 3 — first login with no local subjects: fetch everything from
        // remote. Times out after _kInitRemoteTimeout.
        if (SubjectsController.instance.subjects.isEmpty) {
          try {
            await SubjectsController.instance
                .initFromRemote()
                .timeout(AppTimeouts.initFromRemote);
          } catch (_) {
            // Timed out or failed — subjects remain empty; user can retry later.
          }
        }
        // Always refresh entrance counts from remote so the entrance screen
        // shows correct numbers immediately — whether new user or returning.
        // Times out after _kEntranceCountTimeout.
        try {
          initStatus.value = 'Loading exam info…';
          await SubjectsController.instance
              .refreshEntranceCountsFromRemote()
              .timeout(AppTimeouts.entranceCounts);
        } catch (_) {
          // Timed out or failed — cached counts still shown.
        }
      } else if (isConnected && !networkFetchSucceeded) {
        // Partial connectivity: network seemed available but the fetch failed
        // (e.g. dropped mid-request). If subjects are empty, attempt a
        // best-effort remote fetch with a timeout before navigating.
        if (SubjectsController.instance.subjects.isEmpty) {
          try {
            await SubjectsController.instance
                .initFromRemote()
                .timeout(AppTimeouts.initFromRemote);
            // Reload after remote fetch so subjects list is populated.
            await SubjectsController.instance.loadLocalSubjects();
          } catch (_) {
            // Timed out or failed — navigate with whatever we have.
          }
        }
      }

      initStatus.value = 'Almost done…';
    } catch (_) {
      // Last-resort safety net: even if everything above threw, ensure
      // subjects are loaded from local before navigating.
      try {
        await SubjectsController.instance.loadLocalSubjects();
      } catch (_) {}
    } finally {
      isInitializing.value = false;
    }

    // Navigate to home — all subject/user data is ready at this point.
    Get.offAllNamed(Routes.navigationMenu);

    // Background: entrance count refresh + full delta sync + realtime.
    // None of these block the UI.
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

      // Periodic session check (12 h gap) — runs silently on first launch
      // after login when we already have internet.
      await _periodicSessionCheck();
    } catch (e) {
      AppExceptionHandler.handleResponse(e);
    }
  }

  /// Validates the session against Supabase at most once every 12 hours.
  /// No-ops if offline, not logged in, or the interval hasn't elapsed.
  /// If the device is no longer authorised, [fetchUserRecord] triggers logout.
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

      // Only update timestamp on success so a network failure doesn't
      // reset the clock and delay the next real check.
      if (ok) {
        deviceStorage.write(_kLastSessionCheckKey, now);
      }
    } catch (_) {
      // Non-fatal — never interrupt the user for a background check failure
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
