import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:matricmate/data/database/database_service.dart';
import 'package:matricmate/data/services/fcm_service.dart';
import 'package:matricmate/data/services/payment_config_service.dart';
import 'package:matricmate/features/authentication/models/user_model.dart';
import 'package:matricmate/features/exam/models/question_model.dart';
import 'package:matricmate/features/notifications/controllers/notifications_controller.dart';
import 'package:matricmate/features/notifications/models/notification_model.dart';
import 'package:matricmate/features/personalization/controllers/user_controller.dart';
import 'package:matricmate/routes/app_routes.dart';
import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Listens to Supabase Realtime for:
///   1. Question/explanation edits on subjects the user has downloaded.
///   2. User record updates (e.g. subscription_status: pending → active).
///   3. App config changes (subscription price, payment accounts/holders).
///   4. New / updated notifications for this user (personal + broadcasts).
///   5. Notification read-receipt changes so read state syncs across devices.
///
/// Requires in Supabase:
///   ALTER PUBLICATION supabase_realtime ADD TABLE public.users;
///   ALTER TABLE public.users REPLICA IDENTITY FULL;
///   ALTER PUBLICATION supabase_realtime ADD TABLE public.app_config;
///   ALTER TABLE public.app_config REPLICA IDENTITY FULL;
///   ALTER PUBLICATION supabase_realtime ADD TABLE public.notifications;
///   ALTER TABLE public.notifications REPLICA IDENTITY FULL;
///   ALTER PUBLICATION supabase_realtime ADD TABLE public.notification_reads;
///   ALTER TABLE public.notification_reads REPLICA IDENTITY FULL;
///
/// Usage:
///   RealtimeService.instance.start(downloadedSubjectIds, userId: uid);
///   RealtimeService.instance.stop();   // on sign-out
class RealtimeService {
  RealtimeService._();
  static final RealtimeService instance = RealtimeService._();

  final _supabase = Supabase.instance.client;

  // Five separate channels so each can be removed independently.
  RealtimeChannel? _questionsChannel;
  RealtimeChannel? _userChannel;
  RealtimeChannel? _appConfigChannel;
  RealtimeChannel? _notificationsChannel;
  RealtimeChannel? _notificationReadsChannel;


  /// Start listening. Safe to call multiple times — stops existing first.
  /// [userId] is always required so the user status channel starts even
  /// when the user has no downloaded subjects.
  Future<void> start(List<int> subjectIds, {required String userId}) async {
    await stop();
    _startQuestionChannel(subjectIds);
    _startUserChannel(userId);
    _startAppConfigChannel();
    _startNotificationsChannel(userId);
    _startNotificationReadsChannel(userId);
  }

  /// Stop and clean up all Realtime channels.
  Future<void> stop() async {
    if (_questionsChannel != null) {
      await _supabase.removeChannel(_questionsChannel!);
      _questionsChannel = null;
      debugPrint('[Realtime] unsubscribed from questions');
    }
    if (_userChannel != null) {
      await _supabase.removeChannel(_userChannel!);
      _userChannel = null;
      debugPrint('[Realtime] unsubscribed from user');
    }
    if (_appConfigChannel != null) {
      await _supabase.removeChannel(_appConfigChannel!);
      _appConfigChannel = null;
      debugPrint('[Realtime] unsubscribed from app_config');
    }
    if (_notificationsChannel != null) {
      await _supabase.removeChannel(_notificationsChannel!);
      _notificationsChannel = null;
      debugPrint('[Realtime] unsubscribed from notifications');
    }
    if (_notificationReadsChannel != null) {
      await _supabase.removeChannel(_notificationReadsChannel!);
      _notificationReadsChannel = null;
      debugPrint('[Realtime] unsubscribed from notification_reads');
    }
  }

  // ── Questions channel ─────────────────────────────────────────────────────

  void _startQuestionChannel(List<int> subjectIds) {
    if (subjectIds.isEmpty) return;

    _questionsChannel = _supabase
        .channel('question_edits')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'questions',
          // Supabase Realtime only supports a single eq() filter, so we
          // receive all question updates and filter by subject_id locally.
          callback: (payload) => _onQuestionChanged(payload, subjectIds),
        )
        .subscribe((status, [error]) {
          debugPrint(
            '[Realtime] questions: $status'
            '${error != null ? ' — $error' : ''}',
          );
        });
  }

  Future<void> _onQuestionChanged(
    PostgresChangePayload payload,
    List<int> downloadedSubjectIds,
  ) async {
    try {
      final record = payload.newRecord;
      if (record.isEmpty) return;

      final subjectId = record['subject_id'] as int?;
      if (subjectId == null) return;

      // Ignore updates for subjects the user hasn't downloaded
      if (!downloadedSubjectIds.contains(subjectId)) return;

      final question = QuestionModel.fromMap(record);
      final db = await DatabaseService.instance.database;

      await db.insert(
        'questions',
        question.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      debugPrint('[Realtime] patched question ${question.id}');
    } catch (e) {
      debugPrint('[Realtime] error patching question: $e');
    }
  }

  // ── App-config channel ────────────────────────────────────────────────────

  void _startAppConfigChannel() {
    _appConfigChannel = _supabase
        .channel('app_config_changes')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'app_config',
          callback: (payload) => _onAppConfigChanged(payload),
        )
        .subscribe((status, [error]) {
          debugPrint(
            '[Realtime] app_config: $status'
            '${error != null ? ' — $error' : ''}',
          );
        });
  }

  void _onAppConfigChanged(PostgresChangePayload payload) {
    try {
      if (payload.eventType == PostgresChangeEvent.delete) {
        // For DELETE, oldRecord has the key. Clear the entry and rebuild.
        final record = payload.oldRecord;
        if (record.isEmpty) return;
        PaymentConfigService.instance.deleteKey(
          record['key']?.toString() ?? '',
        );
        debugPrint('[Realtime] app_config deleted: ${record['key']}');
      } else {
        // INSERT / UPDATE — newRecord has the new values.
        final record = payload.newRecord;
        if (record.isEmpty) return;
        PaymentConfigService.instance.applyRow(record);
        debugPrint('[Realtime] app_config updated: ${record['key']}');
      }
    } catch (e) {
      debugPrint('[Realtime] error updating app_config: $e');
    }
  }

  // ── Notifications channel ─────────────────────────────────────────────────

  void _startNotificationsChannel(String userId) {
    if (userId.isEmpty) return;

    // We listen to ALL inserts/updates on the notifications table and
    // filter locally. Supabase Realtime only supports a single eq() filter
    // per channel, but notifications can be either personal (user_id = uid)
    // or broadcast (user_id IS NULL). Receiving all and discarding irrelevant
    // ones is the simplest cross-version approach.
    _notificationsChannel = _supabase
        .channel('notifications_$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          callback: (payload) => _onNotificationInserted(payload, userId),
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'notifications',
          callback: (payload) => _onNotificationUpdated(payload, userId),
        )
        .subscribe((status, [error]) {
          debugPrint(
            '[Realtime] notifications: $status'
            '${error != null ? ' — $error' : ''}',
          );
        });
  }

  Future<void> _onNotificationInserted(
    PostgresChangePayload payload,
    String userId,
  ) async {
    try {
      final record = payload.newRecord;
      if (record.isEmpty) return;

      // Accept personal notifications for this user, or broadcast
      // notifications (user_id is null).
      final rowUserId = record['user_id']?.toString();
      final userStream = UserController.instance.user.value.stream;
      final targetStream = record['target_stream']?.toString();

      final isPersonal = rowUserId == userId;
      final isGlobalBroadcast = rowUserId == null && targetStream == null;
      final isStreamBroadcast =
          rowUserId == null &&
          targetStream != null &&
          userStream.isNotEmpty &&
          targetStream == userStream;

      if (!isPersonal && !isGlobalBroadcast && !isStreamBroadcast) return;

      // Store with this user's id so local queries work correctly.
      final n = AppNotification.fromMap({...record, 'user_id': userId});
      final db = await DatabaseService.instance.database;
      await db.insert(
        'notifications',
        {...n.toMap(), 'is_read': 0},
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );

      // Show an OS notification banner so the user sees it immediately
      // without needing an FCM push from a separate backend function.
      await _showLocalBanner(n);

      // Refresh the controller so the bell badge + list update live.
      if (Get.isRegistered<NotificationsController>()) {
        await NotificationsController.instance.loadNotifications();
      }

      debugPrint('[Realtime] new notification: ${n.title}');
    } catch (e) {
      debugPrint('[Realtime] error inserting notification: $e');
    }
  }

  Future<void> _onNotificationUpdated(
    PostgresChangePayload payload,
    String userId,
  ) async {
    try {
      final record = payload.newRecord;
      if (record.isEmpty) return;

      final rowUserId = record['user_id']?.toString();
      if (rowUserId != null && rowUserId != userId) return;

      final n = AppNotification.fromMap({...record, 'user_id': userId});
      final db = await DatabaseService.instance.database;
      await db.insert(
        'notifications',
        n.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      if (Get.isRegistered<NotificationsController>()) {
        await NotificationsController.instance.loadNotifications();
      }

      debugPrint('[Realtime] updated notification: ${n.id}');
    } catch (e) {
      debugPrint('[Realtime] error updating notification: $e');
    }
  }

  // ── Notification reads channel ────────────────────────────────────────────

  void _startNotificationReadsChannel(String userId) {
    if (userId.isEmpty) return;

    _notificationReadsChannel = _supabase
        .channel('notification_reads_$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notification_reads',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) => _onReadReceiptInserted(payload),
        )
        .subscribe((status, [error]) {
          debugPrint(
            '[Realtime] notification_reads: $status'
            '${error != null ? ' — $error' : ''}',
          );
        });
  }

  Future<void> _onReadReceiptInserted(PostgresChangePayload payload) async {
    try {
      final record = payload.newRecord;
      if (record.isEmpty) return;

      final notifId = record['notification_id'];
      if (notifId == null) return;

      final id = notifId is int ? notifId : int.tryParse(notifId.toString());
      if (id == null) return;

      final db = await DatabaseService.instance.database;
      await db.update(
        'notifications',
        {'is_read': 1},
        where: 'id = ?',
        whereArgs: [id],
      );

      if (Get.isRegistered<NotificationsController>()) {
        await NotificationsController.instance.loadNotifications();
      }

      debugPrint('[Realtime] notification $id marked read');
    } catch (e) {
      debugPrint('[Realtime] error processing read receipt: $e');
    }
  }

  // ── Local notification banner ─────────────────────────────────────────────

  /// Delegates to [FcmService.showBanner] which uses the already-initialised
  /// [FlutterLocalNotificationsPlugin] instance and the registered Android
  /// channel. Creating a second plugin instance here would silently fail
  /// because the channel is only created inside [FcmService.init].
  Future<void> _showLocalBanner(AppNotification n) async {
    await FcmService.instance.showBanner(
      id: n.id,
      title: n.title,
      body: n.body,
      payload: n.type,
    );
  }

  // ── User channel ──────────────────────────────────────────────────────────

  void _startUserChannel(String userId) {
    if (userId.isEmpty) return;

    _userChannel = _supabase
        .channel('user_status_$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'users',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: userId,
          ),
          callback: (payload) => _onUserChanged(payload),
        )
        .subscribe((status, [error]) {
          debugPrint(
            '[Realtime] user: $status'
            '${error != null ? ' — $error' : ''}',
          );
        });
  }

  Future<void> _onUserChanged(PostgresChangePayload payload) async {
    try {
      final record = payload.newRecord;
      if (record.isEmpty) return;

      final updated = UserModel.fromJson(record);
      final previous = UserController.instance.user.value;

      // 1. Persist to local SQLite so the status survives app restarts.
      final db = await DatabaseService.instance.database;
      await db.insert(
        'user',
        updated.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // 2. Update the reactive value — every Obx watching user rebuilds
      //    instantly: badge, banners, content gates, everything.
      UserController.instance.user.value = updated;

      // 3. Notify the user in-app when the admin changes their status,
      //    then lock / unlock the app accordingly.
      if (previous.status != updated.status) {
        _notifyStatusChange(updated);
      }

      debugPrint('[Realtime] user status → ${updated.status}');
    } catch (e) {
      debugPrint('[Realtime] error updating user: $e');
    }
  }

  void _notifyStatusChange(UserModel updated) {
    if (updated.isActive) {
      // Navigate home first, then show the snackbar so it's visible on the
      // home screen instead of the payment/verification screen.
      Get.offAllNamed(Routes.navigationMenu);
      Get.snackbar(
        '🎉 Account Activated',
        'Your subscription is now active. Enjoy full access!',
        duration: const Duration(seconds: 4),
        snackPosition: SnackPosition.TOP,
      );
    } else if (updated.isPending) {
      Get.snackbar(
        '⏳ Payment Pending',
        'Your payment is being verified. We\'ll notify you when it\'s confirmed.',
        duration: const Duration(seconds: 4),
        snackPosition: SnackPosition.TOP,
      );
    } else if (updated.isInactive) {
      // Pop back to home (subjects screen) so the user sees the premium
      // banner and can resubscribe. The banner is already reactive via Obx.
      Get.until((route) => route.isFirst);
      Get.snackbar(
        '🔒 Subscription Ended',
        'Your subscription has been deactivated. Renew to restore access.',
        duration: const Duration(seconds: 5),
        snackPosition: SnackPosition.TOP,
      );
    }
  }
}
