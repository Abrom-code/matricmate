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

/// Listens to Supabase Realtime for question edits, user status, app config, and notifications.
class RealtimeService {
  RealtimeService._();
  static final RealtimeService instance = RealtimeService._();

  final _supabase = Supabase.instance.client;

  // Separate channels for independent lifecycle management
  RealtimeChannel? _questionsChannel;
  RealtimeChannel? _userChannel;
  RealtimeChannel? _appConfigChannel;
  RealtimeChannel? _notificationsChannel;
  RealtimeChannel? _notificationReadsChannel;

  /// Start listening. Safe to call multiple times — stops existing first.
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

  // ── Questions channel ──────────────────────────────────────────────────

  void _startQuestionChannel(List<int> subjectIds) {
    if (subjectIds.isEmpty) return;

    _questionsChannel = _supabase
        .channel('question_edits')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'questions',
          // Realtime only supports single eq() filter; filter by subject locally
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

  // ── App-config channel ─────────────────────────────────────────────────

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
        // DELETE: oldRecord has the key
        final record = payload.oldRecord;
        if (record.isEmpty) return;
        PaymentConfigService.instance.deleteKey(
          record['key']?.toString() ?? '',
        );
        debugPrint('[Realtime] app_config deleted: ${record['key']}');
      } else {
        // INSERT/UPDATE: newRecord has new values
        final record = payload.newRecord;
        if (record.isEmpty) return;
        PaymentConfigService.instance.applyRow(record);
        debugPrint('[Realtime] app_config updated: ${record['key']}');
      }
    } catch (e) {
      debugPrint('[Realtime] error updating app_config: $e');
    }
  }

  // ── Notifications channel ──────────────────────────────────────────────

  void _startNotificationsChannel(String userId) {
    if (userId.isEmpty) return;

    // Listen to all inserts/updates and filter locally (Realtime only supports single eq() filter)
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

      // Accept personal or broadcast notifications (user_id is null)
      final rowUserId = record['user_id']?.toString();
      final userStream = UserController.instance.user.value.stream;
      final targetStream = record['target_stream']?.toString();

      // Normalise both sides to lowercase for case-insensitive match
      final normUserStream = userStream.toLowerCase();
      final normTargetStream = targetStream?.toLowerCase();

      final isPersonal = rowUserId == userId;
      final isGlobalBroadcast = rowUserId == null && targetStream == null;
      final isStreamBroadcast =
          rowUserId == null &&
          normTargetStream != null &&
          normUserStream.isNotEmpty &&
          normTargetStream == normUserStream;

      if (!isPersonal && !isGlobalBroadcast && !isStreamBroadcast) return;

      // Store with this user's id so local queries work correctly.
      final n = AppNotification.fromMap({...record, 'user_id': userId});
      final db = await DatabaseService.instance.database;
      await db.insert('notifications', {
        ...n.toMap(),
        'is_read': 0,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);

      // Show OS banner for this notification
      try {
        await FcmService.instance.showBanner(
          id: n.id,
          title: n.title,
          body: n.body,
          payload: record,
        );
      } catch (e) {
        debugPrint('[Realtime] showBanner failed: $e');
      }

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

  // ── Notification reads channel ─────────────────────────────────────────

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

  // ── User channel ─────────────────────────────────────────────────────────

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

      // 1. Persist to local SQLite
      final db = await DatabaseService.instance.database;
      await db.insert(
        'user',
        updated.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      // 2. Update reactive value — triggers all Obx watchers
      UserController.instance.user.value = updated;

      // 3. Notify user on status change
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
      // Navigate home first so snackbar is visible there
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
      // Pop to home so user sees premium banner
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
