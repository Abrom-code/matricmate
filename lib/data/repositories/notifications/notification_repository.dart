import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:matricmate/data/database/database_service.dart';
import 'package:matricmate/data/services/ensure_supabase_auth.dart';
import 'package:matricmate/features/notifications/models/notification_model.dart';
import 'package:matricmate/utils/exceptions/exception_handler.dart';
import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


/// Handles notification sync between Supabase and local SQLite with per-user read tracking.
class NotificationRepository {
  NotificationRepository({DatabaseService? databaseService})
      : _db = databaseService ?? DatabaseService.instance;

  final DatabaseService _db;
  final SupabaseClient _supabase = Supabase.instance.client;

  String? get _currentUid => FirebaseAuth.instance.currentUser?.uid;

  /// Syncs notifications from Supabase to local SQLite, filtering by stream and signup date.
  Future<void> syncFromRemote(
    String userId,
    String userStream, {
    DateTime? signupAt,
  }) async {
    try {
      debugPrint('[Notifications] syncFromRemote userId=$userId stream=$userStream signupAt=$signupAt');

      // Build date filter for signup-based filtering
      final String? sinceIso = signupAt?.toUtc().toIso8601String();

      // Fetch personal, broadcast, and read receipts in parallel
      final readsQuery = _supabase
          .from('notification_reads')
          .select('notification_id')
          .eq('user_id', userId);

      final List<dynamic> notifFutures;
      if (sinceIso != null) {
        notifFutures = await Future.wait([
          _supabase
              .from('notifications')
              .select()
              .eq('user_id', userId)
              .gte('created_at', sinceIso)
              .order('created_at', ascending: false)
              .limit(100),
          _supabase
              .from('notifications')
              .select()
              .isFilter('user_id', null)
              .gte('created_at', sinceIso)
              .order('created_at', ascending: false)
              .limit(100),
          readsQuery,
        ]);
      } else {
        notifFutures = await Future.wait([
          _supabase
              .from('notifications')
              .select()
              .eq('user_id', userId)
              .order('created_at', ascending: false)
              .limit(100),
          _supabase
              .from('notifications')
              .select()
              .isFilter('user_id', null)
              .order('created_at', ascending: false)
              .limit(100),
          readsQuery,
        ]);
      }

      // Remote dismissals fetch (may fail if table doesn't exist yet)
      List<Map<String, dynamic>> remoteDismissals = [];
      try {
        final raw = await _supabase
            .from('notification_dismissals')
            .select('notification_id')
            .eq('user_id', userId);
        remoteDismissals = List<Map<String, dynamic>>.from(raw as List);
      } catch (_) {
        // Table doesn't exist on Supabase yet — local SQLite handles dismissals.
      }

      final personalRows =
          List<Map<String, dynamic>>.from(notifFutures[0] as List);
      final allBroadcasts =
          List<Map<String, dynamic>>.from(notifFutures[1] as List);
      final readRows =
          List<Map<String, dynamic>>.from(notifFutures[2] as List);

      // Filter broadcasts: keep global or stream-matching (case-insensitive)
      final broadcastRows = allBroadcasts.where((r) {
        final ts = r['target_stream']?.toString() ?? '';
        if (ts.isEmpty) return true;
        return userStream.isNotEmpty &&
            ts.toLowerCase() == userStream.toLowerCase();
      }).toList();

      // Merge + deduplicate by id, sort newest first
      final seen = <dynamic>{};
      final rows = <Map<String, dynamic>>[];
      for (final r in [...personalRows, ...broadcastRows]) {
        if (seen.add(r['id'])) rows.add(r);
      }
      rows.sort((a, b) {
        final ta = DateTime.tryParse(a['created_at']?.toString() ?? '') ??
            DateTime(0);
        final tb = DateTime.tryParse(b['created_at']?.toString() ?? '') ??
            DateTime(0);
        return tb.compareTo(ta);
      });

      debugPrint('[Notifications] fetched ${rows.length} total '
          '(${personalRows.length} personal + ${broadcastRows.length} broadcast), '
          '${readRows.length} reads');

      // Load dismissed IDs from local + remote
      final db = await _db.database;
      final localDismissedRows = await db.query(
        'notification_dismissals',
        columns: ['notification_id'],
        where: 'user_id = ?',
        whereArgs: [userId],
      );
      final dismissedIds = <int>{
        for (final r in localDismissedRows)
          if (r['notification_id'] != null) r['notification_id'] as int,
        for (final r in remoteDismissals)
          if (r['notification_id'] != null)
             (r['notification_id'] is int
                ? r['notification_id'] as int
                : int.tryParse(r['notification_id'].toString()) ?? -1),
      }..remove(-1);

      // Build read-id set
      final readIds = <int>{
        for (final r in readRows)
          if (r['notification_id'] != null)
            (r['notification_id'] is int
                ? r['notification_id'] as int
                : int.tryParse(r['notification_id'].toString()) ?? -1),
      }..remove(-1);

      // Upsert into local SQLite — skip dismissed rows entirely.
      int skipped = 0;
      final batch = db.batch();
      for (final row in rows) {
        final id = (row['id'] is int
                ? row['id'] as int
                : int.tryParse(row['id'].toString())) ??
            0;
        if (dismissedIds.contains(id)) {
          skipped++;
          continue;
        }
        final map = AppNotification.fromMap(row).toMap();
        map['user_id'] = userId; // ensure local rows always have userId
        map['is_read'] = readIds.contains(id) ? 1 : 0;
        batch.insert(
          'notifications',
          map,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
      debugPrint('[Notifications] upserted ${rows.length - skipped} rows to local DB'
          '${skipped > 0 ? " ($skipped dismissed — skipped)" : ""}'
      );
    } catch (e, st) {
      debugPrint('[Notifications] syncFromRemote failed: $e\n$st');
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

  /// Marks a notification as read locally and records it in `notification_reads`.
  Future<void> markRead(int notificationId) async {
    // 1. Update local SQLite immediately — UI reads from here.
    final db = await _db.database;
    await db.update(
      'notifications',
      {'is_read': 1},
      where: 'id = ?',
      whereArgs: [notificationId],
    );

    // Insert into notification_reads (idempotent via PK)
    final uid = _currentUid;
    if (uid == null) return;
    try {
      await ensureSupabaseAuth();
      await _supabase.from('notification_reads').upsert(
        {'notification_id': notificationId, 'user_id': uid},
        onConflict: 'notification_id,user_id',
      );
    } catch (_) {
      // Best-effort — local state is already updated.
    }
  }

  /// Marks all notifications as read for this user.
  Future<void> markAllRead(String userId) async {
    final db = await _db.database;

    // 1. Collect unread IDs before updating — needed for the remote upsert.
    final unread = await db.query(
      'notifications',
      columns: ['id'],
      where: 'user_id = ? AND is_read = 0',
      whereArgs: [userId],
    );

    // 2. Mark all as read locally.
    await db.update(
      'notifications',
      {'is_read': 1},
      where: 'user_id = ?',
      whereArgs: [userId],
    );

    // 3. Bulk-upsert into notification_reads.
    if (unread.isNotEmpty) {
      try {
        final rows = unread
            .map((r) => {'notification_id': r['id'], 'user_id': userId})
            .toList();
        await _supabase.from('notification_reads').upsert(
          rows,
          onConflict: 'notification_id,user_id',
        );
      } catch (_) {}
    }
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

  /// Deletes a notification (personal: from server, broadcast: records dismissal).
  Future<void> deleteNotification(AppNotification n) async {
    final uid = _currentUid;
    final db = await _db.database;

    // 1. Update local SQLite first for immediate UI response.
    await db.transaction((txn) async {
      await txn.delete('notifications', where: 'id = ?', whereArgs: [n.id]);
      if (uid != null) {
        await txn.insert(
          'notification_dismissals',
          {
            'notification_id': n.id,
            'user_id': uid,
            'dismissed_at': DateTime.now().toIso8601String(),
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });

    if (uid == null) return;

    // 2. Sync to Supabase.
    try {
      await ensureSupabaseAuth();
      if (n.userId == uid) {
        // Personal notification: delete permanently from server.
        await _supabase.from('notifications').delete().eq('id', n.id);
      } else {
        // Broadcast notification: track dismissal on server.
        await _supabase.from('notification_dismissals').upsert(
          {'notification_id': n.id, 'user_id': uid},
          onConflict: 'notification_id,user_id',
        );
      }
    } catch (_) {
      // Best-effort. Local DB is updated so UI is correct.
    }
  }

  /// Deletes/dismisses all notifications for [userId].
  Future<void> deleteAllNotifications(String userId, List<AppNotification> notifications) async {
    final db = await _db.database;
    if (notifications.isEmpty) return;

    // 1. Local update
    await db.transaction((txn) async {
      await txn.delete('notifications', where: 'user_id = ?', whereArgs: [userId]);
      final now = DateTime.now().toIso8601String();
      for (final n in notifications) {
        await txn.insert(
          'notification_dismissals',
          {
            'notification_id': n.id,
            'user_id': userId,
            'dismissed_at': now,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });

    // 2. Server update
    try {
      await ensureSupabaseAuth();
      final personalIds = notifications.where((n) => n.userId == userId).map((n) => n.id).toList();
      final broadcastIds = notifications.where((n) => n.userId != userId).map((n) => n.id).toList();

      if (personalIds.isNotEmpty) {
        await _supabase.from('notifications').delete().inFilter('id', personalIds);
      }
      if (broadcastIds.isNotEmpty) {
        final rows = broadcastIds.map((id) => {'notification_id': id, 'user_id': userId}).toList();
        await _supabase.from('notification_dismissals').upsert(
          rows,
          onConflict: 'notification_id,user_id',
        );
      }
    } catch (_) {}
  }

  Future<void> saveFcmToken(String userId, String token) async {
    try {
      await _supabase.from('users').update({'fcm_token': token}).eq('id', userId);
    } catch (_) {
      // Non-fatal — token refresh will retry on next app open.
    }
  }
}
