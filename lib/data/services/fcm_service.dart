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

/// Top-level FCM background handler for isolate message processing.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Guard against duplicate-app if isolate is reused
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  // Skip notification messages — FCM SDK already shows them
  if (message.notification != null) return;

  // Data-only message: show OS banner manually
  const channel = AndroidNotificationChannel(
    'matricmate_default',
    'General Notifications',
    description: 'Announcements, payment updates, and new exam alerts',
    importance: Importance.high,
  );

  final plugin = FlutterLocalNotificationsPlugin();

  await plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(channel);

  await plugin.initialize(
    settings: const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    ),
  );

  final title = message.data['title']?.toString();
  final body = message.data['body']?.toString();

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

/// Wraps FCM + flutter_local_notifications for token management, foreground banners, and tap routing.
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

  bool _initialized = false;

  /// Prevents stale launch notifications from re-navigating on hot restart.
  bool _shouldHandleLaunch(int hash) {
    final storage = GetStorage();
    final lastHash = storage.read<int>('_lastLaunchNotifHash');
    if (lastHash == hash) return false;
    storage.write('_lastLaunchNotifHash', hash);
    return true;
  }

  bool _isRequestingPermission = false;
  DateTime? _lastPermissionCheck;

  /// Requests notification permissions if not already granted.
  Future<NotificationSettings?> requestPermissionIfNeeded() async {
    if (_isRequestingPermission) return null;

    // Cooldown guard to avoid rapid re-checks
    final now = DateTime.now();
    if (_lastPermissionCheck != null &&
        now.difference(_lastPermissionCheck!).inSeconds < 5) {
      return null;
    }

    _isRequestingPermission = true;
    _lastPermissionCheck = now;

    try {
      final settings = await _messaging.getNotificationSettings();
      if (settings.authorizationStatus != AuthorizationStatus.authorized &&
          settings.authorizationStatus != AuthorizationStatus.provisional) {
        await _localNotifications
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >()
            ?.requestNotificationsPermission();

        final updated = await _messaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );

        if (updated.authorizationStatus == AuthorizationStatus.authorized ||
            updated.authorizationStatus == AuthorizationStatus.provisional) {
          final token = await _messaging.getToken();
          await _saveTokenIfLoggedIn(token);
          await _subscribeToStreamTopics();
        }

        return updated;
      }
      return settings;
    } catch (e) {
      debugPrint('[FcmService] requestPermissionIfNeeded error: $e');
      return null;
    } finally {
      _isRequestingPermission = false;
    }
  }

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    await requestPermissionIfNeeded();

    // iOS: show heads-up banner in foreground
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

    // Register/refresh token for personal and stream-based pushes
    final token = await _messaging.getToken();
    await _saveTokenIfLoggedIn(token);
    _messaging.onTokenRefresh.listen(_saveTokenIfLoggedIn);

    // Subscribe to FCM topics for broadcast delivery
    await _subscribeToStreamTopics();

    // Startup race guard: retry token save once userId loads
    if (UserController.instance.user.value.id.isEmpty) {
      Worker? startupSaveWorker;
      startupSaveWorker = ever(UserController.instance.user, (
        UserModel u,
      ) async {
        if (u.id.isNotEmpty) {
          startupSaveWorker?.dispose();
          startupSaveWorker = null;
          await _saveTokenIfLoggedIn(token);
          await _subscribeToStreamTopics();
        }
      });
    }

    FirebaseMessaging.onMessage.listen(_onForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen((m) => _handleTap(m.data));

    // App cold-launched by tapping a FCM notification
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      if (_shouldHandleLaunch(initialMessage.data.hashCode)) {
        _handleTap(initialMessage.data);
      }
    }

    // App cold-launched by tapping a local notification (Realtime banner)
    final launchDetails = await _localNotifications
        .getNotificationAppLaunchDetails();
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

  /// Saves FCM token after login and re-subscribes stream topics.
  Future<void> saveTokenForCurrentUser() async {
    final token = await _messaging.getToken();
    await _saveTokenIfLoggedIn(token);
    await _subscribeToStreamTopics();
  }

  /// Shows a local notification banner with full payload for deep-link routing.
  Future<void> showBanner({
    required int id,
    required String title,
    required String body,
    Map<String, dynamic>? payload,
  }) async {
    try {
      // Encode full payload for tap routing
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

    // Skip snackbar for types already handled by Realtime
    if (type != 'announcement' && type != 'new_content') {
      // Show in-app snackbar for payment/test notifications
      if (type == 'payment_status' || type == 'payment') {
        final title =
            notification?.title ??
            message.data['title']?.toString() ??
            'Payment Update';
        final body =
            notification?.body ?? message.data['body']?.toString() ?? '';
        Get.snackbar(
          title,
          body,
          duration: const Duration(seconds: 5),
          snackPosition: SnackPosition.TOP,
        );
      } else if (type == 'new_test') {
        final title = notification?.title ?? 'New Test Available';
        final body = notification?.body ?? '';
        Get.snackbar(
          title,
          body,
          duration: const Duration(seconds: 4),
          snackPosition: SnackPosition.TOP,
        );
      }
    }

    // Show OS banner manually — FCM suppresses it in foreground
    final title = notification?.title ?? message.data['title']?.toString();
    final body = notification?.body ?? message.data['body']?.toString();
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
    // Route tap to appropriate screen based on notification type
    final type = data['type']?.toString();
    if (data.containsKey('challenge_id') ||
        type == 'challenge' ||
        type == 'challenge_round' ||
        type == 'challenge_reward') {
      NotificationTestOpener.open(data);
      return;
    }

    switch (type) {
      case 'payment':
      case 'payment_status':
        Get.toNamed(Routes.paymentVerification);
        break;
      case 'new_content':
      case 'new_test':
        NotificationTestOpener.open(data);
        break;
      default:
        // Sync so notification appears in list immediately
        if (Get.isRegistered<NotificationsController>()) {
          NotificationsController.instance.loadNotifications(syncRemote: true);
        }
        Get.toNamed(Routes.notifications);
    }
  }

  /// Unsubscribes from all topics on logout.
  Future<void> unsubscribeAll() async {
    await _messaging.unsubscribeFromTopic('all_users');
    await _messaging.unsubscribeFromTopic('natural');
    await _messaging.unsubscribeFromTopic('social');
    _initialized = false;
  }

  /// Subscribes to 'all_users' and the user's stream topic.
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
