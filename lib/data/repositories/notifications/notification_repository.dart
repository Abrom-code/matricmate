import 'package:flutter/foundation.dart';
import 'package:matricmate/data/database/database_service.dart';
import 'package:matricmate/features/notifications/models/notification_model.dart';
import 'package:matricmate/utils/constants/app_timeouts.dart';
import 'package:matricmate/utils/exceptions/exception_handler.dart';
import 'package:matricmate/utils/network_manager/network_manager.dart';
import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Handles notification sync between Supabase and local SQLite with per-user read tracking.
class NotificationRepository {
  NotificationRepository({DatabaseService? databaseService})
    : _db = databaseService ?? DatabaseService.instance;

  final DatabaseService _db;
  final SupabaseClient _supabase = Supabase.instance.client;

  String? get _currentUid => _supabase.auth.currentUser?.id;

  /// Syncs notifications from Supabase to local SQLite, filtering by stream and signup date.
  Future<void> syncFromRemote(
    String userId,
    String userStream, {
    DateTime? signupAt,
  }) async {
    final isOnline = await NetworkManager.instance.isConnected();
    if (!isOnline) {
      debugPrint('[Notifications] Device offline — skipping remote sync');
      return;
    }

    try {
      debugPrint(
        '[Notifications] syncFromRemote userId=$userId stream=$userStream signupAt=$signupAt',
      );

      // Delta sync: If we already have notifications locally, only fetch notifications created
      // after the newest local one (with a 2-second safety buffer). Otherwise fall back to signup date.
      final db = await _db.database;
      DateTime? effectiveSince = signupAt;
      final latestLocalRows = await db.rawQuery(
        'SELECT created_at FROM notifications WHERE user_id = ? OR user_id = \'\' ORDER BY created_at DESC LIMIT 1',
        [userId],
      );
      if (latestLocalRows.isNotEmpty && latestLocalRows.first['created_at'] != null) {
        final parsed = DateTime.tryParse(latestLocalRows.first['created_at'].toString());
        if (parsed != null) {
          effectiveSince = parsed.subtract(const Duration(seconds: 2));
        }
      }

      final String? sinceIso = effectiveSince?.toUtc().toIso8601String();

      // 1. Fetch personal and broadcast notifications in ONE single consolidated query
      List<Map<String, dynamic>> rawRows;
      try {
        var query = _supabase
            .from('notifications')
            .select()
            .or('user_id.eq.$userId,user_id.is.null');

        if (sinceIso != null) {
          query = query.gte('created_at', sinceIso);
        }

        final response = await query
            .order('created_at', ascending: false)
            .limit(100)
            .timeout(AppTimeouts.sync);
        rawRows = List<Map<String, dynamic>>.from(response as List);
      } catch (e) {
        debugPrint('[Notifications] Combined query failed, falling back to parallel: $e');
        final results = await Future.wait([
          sinceIso != null
              ? _supabase
                  .from('notifications')
                  .select()
                  .eq('user_id', userId)
                  .gte('created_at', sinceIso)
                  .order('created_at', ascending: false)
                  .limit(100)
              : _supabase
                  .from('notifications')
                  .select()
                  .eq('user_id', userId)
                  .order('created_at', ascending: false)
                  .limit(100),
          sinceIso != null
              ? _supabase
                  .from('notifications')
                  .select()
                  .isFilter('user_id', null)
                  .gte('created_at', sinceIso)
                  .order('created_at', ascending: false)
                  .limit(100)
              : _supabase
                  .from('notifications')
                  .select()
                  .isFilter('user_id', null)
                  .order('created_at', ascending: false)
                  .limit(100),
        ]).timeout(AppTimeouts.sync);
        rawRows = [
          ...List<Map<String, dynamic>>.from(results[0] as List),
          ...List<Map<String, dynamic>>.from(results[1] as List),
        ];
      }

      // Filter broadcasts: keep global or stream-matching (case-insensitive)
      final broadcastRows = rawRows.where((r) {
        final ts = r['target_stream']?.toString() ?? '';
        if (ts.isEmpty) return true;
        return userStream.isNotEmpty &&
            ts.toLowerCase() == userStream.toLowerCase();
      }).toList();

      // Merge + deduplicate by id, sort newest first
      final seen = <dynamic>{};
      final rows = <Map<String, dynamic>>[];
      for (final r in broadcastRows) {
        if (seen.add(r['id'])) rows.add(r);
      }
      rows.sort((a, b) {
        final ta =
            DateTime.tryParse(a['created_at']?.toString() ?? '') ?? DateTime(0);
        final tb =
            DateTime.tryParse(b['created_at']?.toString() ?? '') ?? DateTime(0);
        return tb.compareTo(ta);
      });

      debugPrint(
        '[Notifications] fetched ${rows.length} notifications via single consolidated request',
      );

      // Load dismissed IDs from local SQLite
      final localDismissedRows = await db.query(
        'notification_dismissals',
        columns: ['notification_id'],
        where: 'user_id = ? OR user_id = \'\'',
        whereArgs: [userId],
      );
      final dismissedIds = <int>{
        for (final r in localDismissedRows)
          if (r['notification_id'] != null)
            (r['notification_id'] is int
                ? r['notification_id'] as int
                : int.tryParse(r['notification_id'].toString()) ?? -1),
      }..remove(-1);

      // Clean up any stale dismissed notifications lingering in local DB
      if (dismissedIds.isNotEmpty) {
        final placeholders = List.filled(dismissedIds.length, '?').join(',');
        await db.delete(
          'notifications',
          where: 'id IN ($placeholders)',
          whereArgs: dismissedIds.toList(),
        );
      }

      // Query which notifications are already marked read in local SQLite
      final existingLocalRows = await db.query(
        'notifications',
        columns: ['id', 'is_read'],
        where: 'user_id = ? OR user_id = \'\'',
        whereArgs: [userId],
      );
      final localReadIds = <int>{
        for (final r in existingLocalRows)
          if ((r['is_read'] as num?)?.toInt() == 1)
            (r['id'] is int
                ? r['id'] as int
                : int.tryParse(r['id'].toString()) ?? -1),
      }..remove(-1);

      // Upsert into local SQLite — preserve local is_read status; skip dismissed rows entirely.
      int skipped = 0;
      final batch = db.batch();
      for (final row in rows) {
        final id =
            (row['id'] is int
                ? row['id'] as int
                : int.tryParse(row['id'].toString())) ??
            0;
        if (dismissedIds.contains(id)) {
          skipped++;
          continue;
        }
        final map = AppNotification.fromMap(row).toMap();
        map['user_id'] = userId; // ensure local rows always have userId
        // Preserves read state locally on this device; newly arrived remote notifications are unread (0)
        map['is_read'] = localReadIds.contains(id) ? 1 : 0;
        batch.insert(
          'notifications',
          map,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
      debugPrint(
        '[Notifications] upserted ${rows.length - skipped} rows to local DB'
        '${skipped > 0 ? " ($skipped dismissed — skipped)" : ""}',
      );
    } catch (e) {
      debugPrint('[Notifications] syncFromRemote failed: $e');
      throw AppExceptionHandler.handle(e);
    }
  }

  Future<List<AppNotification>> getLocal(String userId) async {
    final db = await _db.database;
    final rows = await db.query(
      'notifications',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );
    return rows.map((r) => AppNotification.fromMap(r)).toList();
  }

  Future<int> getUnreadCount(String userId) async {
    final db = await _db.database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as cnt FROM notifications WHERE user_id = ? AND is_read = 0',
      [userId],
    );
    return result.first['cnt'] as int? ?? 0;
  }

  /// Marks a notification as read locally in SQLite.
  /// Zero network overhead — UI updates immediately (0ms).
  Future<void> markRead(int notificationId) async {
    final db = await _db.database;
    await db.update(
      'notifications',
      {'is_read': 1},
      where: 'id = ?',
      whereArgs: [notificationId],
    );
  }

  /// Marks all notifications as read for this user locally in SQLite.
  /// Zero network overhead — UI updates immediately (0ms).
  Future<void> markAllRead(String userId) async {
    final db = await _db.database;
    await db.update(
      'notifications',
      {'is_read': 1},
      where: 'user_id = ? OR user_id = \'\'',
      whereArgs: [userId],
    );
  }

  /// Inserts a notification locally for immediate UI update.
  Future<void> insertLocal(AppNotification n) async {
    final db = await _db.database;
    await db.insert(
      'notifications',
      n.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Atomic bulk delete and dismissal recording for [items].
  ///
  /// Local SQLite deletes rows and records dismissals immediately (<5ms).
  /// Personal notifications are cleaned up from Supabase via a single best-effort call.
  Future<void> deleteNotifications(
    String userId,
    List<AppNotification> items,
  ) async {
    final effectiveUid = userId.isNotEmpty ? userId : (_currentUid ?? '');
    final db = await _db.database;
    if (items.isEmpty || effectiveUid.isEmpty) return;

    final ids = items.map((e) => e.id).toList();

    // 1. Immediate local SQLite update in a single atomic transaction
    await db.transaction((txn) async {
      final placeholders = List.filled(ids.length, '?').join(',');
      await txn.delete(
        'notifications',
        where: 'id IN ($placeholders)',
        whereArgs: ids,
      );
      final now = DateTime.now().toIso8601String();
      for (final id in ids) {
        await txn.insert(
          'notification_dismissals',
          {
            'notification_id': id,
            'user_id': effectiveUid,
            'dismissed_at': now,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });

    // 2. Best-effort server cleanup: delete personal notifications owned by this user
    try {
      await _supabase
          .from('notifications')
          .delete()
          .inFilter('id', ids)
          .eq('user_id', effectiveUid)
          .timeout(AppTimeouts.bestEffort);
    } catch (_) {}
  }

  /// Deletes a single notification for [userId].
  Future<void> deleteNotification(String userId, AppNotification n) async {
    await deleteNotifications(userId, [n]);
  }

  /// Deletes/dismisses all notifications for [userId] thoroughly.
  Future<void> deleteAllNotifications(
    String userId,
    List<AppNotification> notifications,
  ) async {
    final effectiveUid = userId.isNotEmpty ? userId : (_currentUid ?? '');
    final db = await _db.database;

    // 1. Find all notification IDs currently in local SQLite (not just in-memory list)
    final localRows = await db.query(
      'notifications',
      columns: ['id'],
    );
    final allIds = <int>{
      for (final r in localRows)
        if (r['id'] is int)
          r['id'] as int
        else
          int.tryParse(r['id'].toString()) ?? 0,
      for (final n in notifications) n.id,
    }..remove(0);

    // 2. Wipe notifications table locally in SQLite
    await db.transaction((txn) async {
      await txn.delete('notifications');

      final now = DateTime.now().toIso8601String();
      for (final id in allIds) {
        await txn.insert(
          'notification_dismissals',
          {
            'notification_id': id,
            'user_id': effectiveUid,
            'dismissed_at': now,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });

    // 3. Best-effort server cleanup: delete personal notifications owned by this user
    if (effectiveUid.isNotEmpty && allIds.isNotEmpty) {
      try {
        await _supabase
            .from('notifications')
            .delete()
            .inFilter('id', allIds.toList())
            .eq('user_id', effectiveUid)
            .timeout(AppTimeouts.bestEffort);
      } catch (_) {}
    }
  }

  /// Restores previously deleted notifications on undo.
  Future<void> restoreNotifications(
    String userId,
    List<AppNotification> items,
  ) async {
    final effectiveUid = userId.isNotEmpty ? userId : (_currentUid ?? '');
    final db = await _db.database;
    if (items.isEmpty || effectiveUid.isEmpty) return;

    final ids = items.map((e) => e.id).toList();

    // Restore rows and remove dismissals locally in a single atomic transaction
    await db.transaction((txn) async {
      final placeholders = List.filled(ids.length, '?').join(',');
      await txn.delete(
        'notification_dismissals',
        where: 'notification_id IN ($placeholders) AND user_id = ?',
        whereArgs: [...ids, effectiveUid],
      );
      for (final item in items) {
        final map = item.toMap();
        map['user_id'] = effectiveUid;
        await txn.insert(
          'notifications',
          map,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  Future<void> saveFcmToken(String userId, String token) async {
    try {
      await _supabase
          .from('users')
          .update({'fcm_token': token})
          .eq('id', userId)
          .timeout(AppTimeouts.bestEffort);
    } catch (_) {
      // Non-fatal — token refresh will retry on next app open.
    }
  }
}
