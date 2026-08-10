import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:matricmate/data/repositories/notifications/notification_repository.dart';
import 'package:matricmate/features/notifications/controllers/notifications_controller.dart';
import 'package:matricmate/features/notifications/models/notification_model.dart';
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
///      Supabase (`users.fcm_token`) for personal pushes (payment updates).
///   2. Subscribe the device to `all_users` + `stream_<natural|social>`
///      topics so broadcast/new-content pushes can target by stream
///      without per-user fan-out.
///   3. Show a local notification banner when a push arrives in the
///      foreground (FCM does this automatically in background/terminated).
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

  String? _subscribedStreamTopic;
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

    // Broadcast topic — everyone gets general announcements.
    await _messaging.subscribeToTopic('all_users');

    // Stream topic — subscribe now, and keep in sync if the user changes
    // their stream later (Edit Profile).
    await _syncStreamTopic(UserController.instance.user.value.stream);
    _streamWatcher = ever<dynamic>(
      UserController.instance.user,
      (user) => _syncStreamTopic(user.stream as String),
    );

    FirebaseMessaging.onMessage.listen(_onForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen((m) => _handleTap(m.data));

    // App was fully closed and launched by tapping a notification.
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) _handleTap(initialMessage.data);
  }

  Future<void> _saveTokenIfLoggedIn(String? token) async {
    if (token == null) return;
    final userId = UserController.instance.user.value.id;
    if (userId.isEmpty) return;
    await _repo.saveFcmToken(userId, token);
  }

  /// Keeps the device subscribed to exactly one stream topic at a time.
  Future<void> _syncStreamTopic(String stream) async {
    if (stream.isEmpty || stream == _subscribedStreamTopic) return;

    final newTopic = 'stream_$stream'; // 'stream_natural' | 'stream_social'

    if (_subscribedStreamTopic != null) {
      await _messaging.unsubscribeFromTopic(_subscribedStreamTopic!);
    }
    await _messaging.subscribeToTopic(newTopic);
    _subscribedStreamTopic = newTopic;
  }

  Future<void> _onForegroundMessage(RemoteMessage message) async {
    final notification = message.notification;
    final userId = UserController.instance.user.value.id;

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

    if (userId.isNotEmpty) {
      final n = AppNotification(
        id:
            message.messageId?.hashCode ??
            DateTime.now().millisecondsSinceEpoch,
        userId: userId,
        title: notification?.title ?? message.data['title'] ?? 'Notification',
        body: notification?.body ?? message.data['body'] ?? '',
        type: message.data['type'] ?? 'announcement',
        payload: message.data,
        isRead: false,
        createdAt: DateTime.now(),
      );

      if (Get.isRegistered<NotificationsController>()) {
        await Get.find<NotificationsController>().insertFromPush(n);
      } else {
        await _repo.insertLocal(n);
      }
    }
  }

  void _handleTap(Map<String, dynamic> data) {
    switch (data['type']) {
      case 'payment':
        Get.toNamed(Routes.paymentVerification);
        break;
      case 'new_content':
        NotificationTestOpener.open(data);
        break;
      default:
        Get.toNamed(Routes.notifications);
    }
  }

  /// Call on logout so a signed-out device stops receiving another user's
  /// personal/stream notifications.
  Future<void> unsubscribeAll() async {
    await _messaging.unsubscribeFromTopic('all_users');
    if (_subscribedStreamTopic != null) {
      await _messaging.unsubscribeFromTopic(_subscribedStreamTopic!);
      _subscribedStreamTopic = null;
    }
    _streamWatcher?.dispose();
    _streamWatcher = null;
    _initialized = false;
  }
}
