import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:matricmate/data/repositories/notifications/notification_repository.dart';
import 'package:matricmate/features/notifications/services/notification_navigator.dart';
import 'package:matricmate/features/personalization/controllers/user_controller.dart';
import 'package:matricmate/routes/app_routes.dart';

/// Must be a top-level (or static) function — required by the Flutter
/// background isolate contract for FCM background messages.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // The OS shows the notification tray entry from the FCM "notification"
  // payload automatically here — nothing to do unless you later want to
  // persist data-only background messages to SQLite directly.
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

  String? _subscribedStreamTopic; // kept for unsubscribeAll backward compat
  Worker? _streamWatcher;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    await _messaging.requestPermission(alert: true, badge: true, sound: true);

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

    // Register/refresh the token used for personal (payment) pushes.
    final token = await _messaging.getToken();

    await _saveTokenIfLoggedIn(token);
    _messaging.onTokenRefresh.listen(_saveTokenIfLoggedIn);

    // all_users topic covers global announcements sent via topic (legacy path).
    // Stream-specific pushes now use per-token fan-out in the edge function
    // (queries users table by stream column directly), so no stream topic
    // subscription is needed on the client side.
    await _messaging.subscribeToTopic('all_users');

    FirebaseMessaging.onMessage.listen(_onForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen((m) => _handleTap(m.data));

    // App was fully closed and launched by tapping a FCM notification.
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) _handleTap(initialMessage.data);

    // App was fully closed and launched by tapping a local notification
    // (Realtime-delivered banner shown via showBanner).
    final launchDetails = await _localNotifications.getNotificationAppLaunchDetails();
    if (launchDetails?.didNotificationLaunchApp == true) {
      final payload = launchDetails!.notificationResponse?.payload;
      if (payload != null && payload.isNotEmpty) {
        try {
          _handleTap(Map<String, dynamic>.from(jsonDecode(payload)));
        } catch (_) {}
      }
    }
  }

  Future<void> _saveTokenIfLoggedIn(String? token) async {
    if (token == null) return;
    final userId = UserController.instance.user.value.id;
    if (userId.isEmpty) return;
    await _repo.saveFcmToken(userId, token);
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

    // announcement and new_content are delivered via Supabase Realtime when
    // the app is open — Realtime already inserted the row and updated the
    // badge. Showing a second OS banner here would be a duplicate.
    // Only process types that Realtime does NOT cover.
    if (type == 'announcement' || type == 'new_content') return;

    final notification = message.notification;

    // For payment_status and new_test: show an in-app snackbar so the user
    // gets immediate feedback, then also show the OS banner (FCM suppresses
    // it automatically in the foreground).
    if (type == 'payment_status' || type == 'payment') {
      final status = message.data['status']?.toString() ?? '';
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

    // Show the OS banner for all non-Realtime types. FCM suppresses it
    // automatically in the foreground, so we do it manually here.
    if (notification != null) {
      await _localNotifications.show(
        id: message.hashCode,
        title: notification.title,
        body: notification.body,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            channelDescription: _channel.description,
            importance: Importance.high,
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
        Get.toNamed(Routes.notifications);
    }
  }

  /// Call on logout so a signed-out device stops receiving another user's
  /// personal notifications.
  Future<void> unsubscribeAll() async {
    await _messaging.unsubscribeFromTopic('all_users');
    _streamWatcher?.dispose();
    _streamWatcher = null;
    _initialized = false;
  }
}
