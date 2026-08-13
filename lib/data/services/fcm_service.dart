import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:get_storage/get_storage.dart';
import 'package:matricmate/firebase_options.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:matricmate/data/repositories/notifications/notification_repository.dart';
import 'package:matricmate/features/notifications/controllers/notifications_controller.dart';
import 'package:matricmate/features/notifications/services/notification_navigator.dart';
import 'package:matricmate/features/authentication/models/user_model.dart';
import 'package:matricmate/features/personalization/controllers/user_controller.dart';
import 'package:matricmate/routes/app_routes.dart';

/// Must be a top-level (or static) function — required by the Flutter
/// background isolate contract for FCM background messages.
///
/// Runs in a **separate Dart isolate** (no GetX, no controllers, no Supabase).
///
/// ── How Android background delivery works ─────────────────────────────────
/// When the app is killed/backgrounded and a FCM *notification message*
/// (includes a `notification` object) arrives:
///   1. The FCM Android SDK shows the OS banner automatically — no Dart
///      code is needed for this step.
///   2. The SDK then spawns this background isolate and calls this handler
///      for any extra data processing (e.g. badge update, DB write).
///
/// For *data-only* messages (no `notification` key) step 1 is skipped, so
/// we must show the banner ourselves via flutter_local_notifications.
///
/// ── What we do here ───────────────────────────────────────────────────────
///   • Always: Firebase.initializeApp() with options (required in isolate).
///   • Data-only only: create channel + show notification manually.
///   • Notification messages: do nothing extra — FCM already showed it.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Guard against [core/duplicate-app] if the isolate is reused.
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  // Only handle data-only messages manually.
  // Notification messages are already shown by the FCM SDK — doing it again
  // here would produce duplicate banners.
  if (message.notification != null) return;

  // ── Data-only message: show the OS banner manually ──────────────────────
  const channel = AndroidNotificationChannel(
    'matricmate_default',
    'General Notifications',
    description: 'Announcements, payment updates, and new exam alerts',
    importance: Importance.high,
  );

  final plugin = FlutterLocalNotificationsPlugin();

  await plugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(channel);

  await plugin.initialize(
    settings: const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    ),
  );

  final title = message.data['title']?.toString();
  final body  = message.data['body']?.toString();

  if (title != null && body != null) {
    await plugin.show(
      id: message.hashCode & 0x7FFFFFFF,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          channel.id,
          channel.name,
          channelDescription: channel.description,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: jsonEncode(message.data),
    );
  }
}


/// Wraps Firebase Cloud Messaging + flutter_local_notifications.
///
/// Responsibilities:
///   1. Request permission, register/refresh the device's FCM token to
///      Supabase (`users.fcm_token`) for personal and stream-based pushes.
///      The edge function queries users by stream column directly — no topic
///      subscription is needed on the client side for stream delivery.
///   2. Subscribe the device to the `all_users` topic for global broadcast
///      announcements sent via the legacy topic path.
///   3. Show an in-app snackbar when a payment/new_test push arrives in the
///      foreground. Ignore announcement/new_content in the foreground —
///      Supabase Realtime already handled those.
///   4. Route notification taps to the right screen — payment status,
///      the exact test via [NotificationTestOpener], or the notifications
///      list as a fallback.
class FcmService {
  FcmService._();
  static final FcmService instance = FcmService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final NotificationRepository _repo = NotificationRepository();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'matricmate_default',
    'General Notifications',
    description: 'Announcements, payment updates, and new exam alerts',
    importance: Importance.high,
  );

  Worker? _streamWatcher;
  bool _initialized = false;

  /// Prevents stale launch notifications from triggering navigation on hot
  /// restart. Android's getNotificationAppLaunchDetails() caches the result
  /// until the activity is fully destroyed, so every hot restart would
  /// re-navigate without this guard.
  bool _shouldHandleLaunch(int hash) {
    final storage = GetStorage();
    final lastHash = storage.read<int>('_lastLaunchNotifHash');
    if (lastHash == hash) return false;
    storage.write('_lastLaunchNotifHash', hash);
    return true;
  }

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    await _messaging.requestPermission(alert: true, badge: true, sound: true);

    // iOS: show heads-up banner even when the app is in the foreground.
    // Without this, FCM silently delivers the message on iOS but the OS
    // never shows a visible alert while the app is open.
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_channel);

    await _localNotifications.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
      onDidReceiveNotificationResponse: (response) {
        if (response.payload == null || response.payload!.isEmpty) return;
        try {
          _handleTap(Map<String, dynamic>.from(jsonDecode(response.payload!)));
        } catch (_) {}
      },
    );

    // Register/refresh the token used for personal and stream-based pushes.
    final token = await _messaging.getToken();
    await _saveTokenIfLoggedIn(token);
    _messaging.onTokenRefresh.listen(_saveTokenIfLoggedIn);

    // Subscribe to FCM topics so the edge function can broadcast by topic
    // ('all_users', 'natural', 'social') without needing to query every
    // device's token individually.
    await _subscribeToStreamTopics();

    // Guard against the startup race: if init() ran before the user finished
    // loading from SQLite, userId was empty and _saveTokenIfLoggedIn was a
    // no-op. Watch for the first non-empty userId and retry exactly once.
    if (UserController.instance.user.value.id.isEmpty) {
      Worker? startupSaveWorker;
      startupSaveWorker = ever(
        UserController.instance.user,
        (UserModel u) async {
          if (u.id.isNotEmpty) {
            startupSaveWorker?.dispose();
            startupSaveWorker = null;
            await _saveTokenIfLoggedIn(token);
            await _subscribeToStreamTopics();
          }
        },
      );
    }

    FirebaseMessaging.onMessage.listen(_onForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen((m) => _handleTap(m.data));

    // App was fully closed and launched by tapping a FCM notification.
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      if (_shouldHandleLaunch(initialMessage.data.hashCode)) {
        _handleTap(initialMessage.data);
      }
    }

    // App was fully closed and launched by tapping a local notification
    // (Realtime-delivered banner shown via showBanner).
    // getNotificationAppLaunchDetails() returns stale data on hot restart
    // (Android caches it until the activity is destroyed), so we guard
    // with _shouldHandleLaunch to prevent duplicate navigation.
    final launchDetails = await _localNotifications.getNotificationAppLaunchDetails();
    if (launchDetails?.didNotificationLaunchApp == true) {
      final payload = launchDetails!.notificationResponse?.payload;
      if (payload != null && payload.isNotEmpty) {
        final hash = payload.hashCode;
        if (_shouldHandleLaunch(hash)) {
          try {
            _handleTap(Map<String, dynamic>.from(jsonDecode(payload)));
          } catch (_) {}
        }
      }
    }
  }

  Future<void> _saveTokenIfLoggedIn(String? token) async {
    if (token == null) return;
    final userId = UserController.instance.user.value.id;
    if (userId.isEmpty) return;
    debugPrint('[FcmService] saving FCM token for userId=$userId');
    await _repo.saveFcmToken(userId, token);
  }

  /// Call this after login/fetchUserRecord completes so the token is
  /// persisted even if init() ran before the user was loaded. Also
  /// re-subscribes stream topics so a profile stream change takes effect.
  Future<void> saveTokenForCurrentUser() async {
    final token = await _messaging.getToken();
    await _saveTokenIfLoggedIn(token);
    await _subscribeToStreamTopics();
  }

  /// Shows a local notification banner using this service's already-initialised
  /// plugin instance. Called by [RealtimeService] so Supabase-inserted
  /// notifications display the same OS banner as FCM-delivered ones.
  ///
  /// [payload] should be the full notification data map (including `type`,
  /// `test_id`, `subject_id`, etc.) so tapping the banner can deep-link
  /// correctly via [_handleTap]. Passing only a type string would lose
  /// all routing data for `new_content` notifications.
  Future<void> showBanner({
    required int id,
    required String title,
    required String body,
    Map<String, dynamic>? payload,
  }) async {
    try {
      // Encode the full payload map so onDidReceiveNotificationResponse can
      // decode it and pass it to _handleTap with all routing fields intact.
      final encoded = jsonEncode(payload ?? {'type': 'announcement'});
      await _localNotifications.show(
        id: id & 0x7FFFFFFF,
        title: title,
        body: body,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            channelDescription: _channel.description,
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        payload: encoded,
      );
    } catch (e) {
      debugPrint('[FcmService] showBanner failed: $e');
    }
  }

  Future<void> _onForegroundMessage(RemoteMessage message) async {
    final type = message.data['type']?.toString() ?? '';
    final notification = message.notification;

    // announcement and new_content: Supabase Realtime handles the OS banner
    // when the app is open (via showBanner). FCM still delivers these in the
    // foreground, but Realtime will have already shown the banner — skip the
    // snackbar for these types to avoid duplicates.
    if (type != 'announcement' && type != 'new_content') {
      // For payment_status and new_test: show an in-app snackbar.
      if (type == 'payment_status' || type == 'payment') {
        final title = notification?.title ?? message.data['title']?.toString() ?? 'Payment Update';
        final body  = notification?.body  ?? message.data['body']?.toString()  ?? '';
        Get.snackbar(
          title,
          body,
          duration: const Duration(seconds: 5),
          snackPosition: SnackPosition.TOP,
        );
      } else if (type == 'new_test') {
        final title = notification?.title ?? 'New Test Available';
        final body  = notification?.body  ?? '';
        Get.snackbar(
          title,
          body,
          duration: const Duration(seconds: 4),
          snackPosition: SnackPosition.TOP,
        );
      }
    }

    // Show the OS banner for all types. FCM suppresses it automatically in
    // the foreground, so we do it manually here. For announcement/new_content
    // Realtime will also call showBanner — if Realtime is connected the IDs
    // may collide and the duplicate is silently dropped by the OS; if
    // Realtime is not connected (reconnect gap) this ensures the banner still
    // appears.
    final title = notification?.title ?? message.data['title']?.toString();
    final body  = notification?.body  ?? message.data['body']?.toString();
    if (title != null && body != null) {
      await _localNotifications.show(
        id: message.hashCode & 0x7FFFFFFF,
        title: title,
        body: body,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            channelDescription: _channel.description,
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        payload: jsonEncode(message.data),
      );
    }
  }

  void _handleTap(Map<String, dynamic> data) {
    // 'payment_status' is the FCM data key sent by the edge function.
    // 'payment' is the type stored in the notifications DB row.
    // Both should navigate to the payment verification screen.
    switch (data['type']) {
      case 'payment':
      case 'payment_status':
        Get.toNamed(Routes.paymentVerification);
        break;
      case 'new_content':
      case 'new_test':
        NotificationTestOpener.open(data);
        break;
      default:
        // Trigger a remote sync so the pushed notification is in local SQLite
        // by the time the notifications screen builds its list.
        if (Get.isRegistered<NotificationsController>()) {
          NotificationsController.instance.loadNotifications(syncRemote: true);
        }
        Get.toNamed(Routes.notifications);
    }
  }

  /// Call on logout so a signed-out device stops receiving another user's
  /// personal notifications.
  Future<void> unsubscribeAll() async {
    await _messaging.unsubscribeFromTopic('all_users');
    await _messaging.unsubscribeFromTopic('natural');
    await _messaging.unsubscribeFromTopic('social');
    _streamWatcher?.dispose();
    _streamWatcher = null;
    _initialized = false;
  }

  /// Subscribes to 'all_users' plus the user's stream topic ('natural' or
  /// 'social'). Called at init and again after the user loads (startup race
  /// guard) and after a stream change in Edit Profile.
  Future<void> _subscribeToStreamTopics() async {
    try {
      await _messaging.subscribeToTopic('all_users');
      final stream = UserController.instance.user.value.stream.toLowerCase();
      if (stream == 'natural') {
        await _messaging.subscribeToTopic('natural');
        await _messaging.unsubscribeFromTopic('social');
      } else if (stream == 'social') {
        await _messaging.subscribeToTopic('social');
        await _messaging.unsubscribeFromTopic('natural');
      }
    } catch (e) {
      debugPrint('[FcmService] topic subscription failed: $e');
    }
  }
}
