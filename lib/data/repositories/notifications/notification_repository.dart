import 'package:matricmate/data/database/database_service.dart';
import 'package:matricmate/features/notifications/models/notification_model.dart';
import 'package:matricmate/utils/exceptions/exception_handler.dart';
import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Mirrors the pattern used by SyncRepository/TestRepository elsewhere in
/// the app: Supabase is the source of truth, SQLite is the local cache the
/// UI actually reads from, so the bell/list stays accurate even offline.
class NotificationRepository {
  NotificationRepository({DatabaseService? databaseService})
      : _db = databaseService ?? DatabaseService.instance;

  final DatabaseService _db;
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Pulls this user's personal notifications PLUS any broadcast rows that
  /// match their stream (or are global — target_stream IS NULL), and
  /// upserts them into local SQLite.
  ///
  /// Broadcast rows have no `user_id` server-side; we stamp the current
  /// device's user id onto the local copy so getLocal()/getUnreadCount()
  /// filtering by user_id continues to work unmodified.
  Future<void> syncFromRemote(String userId, String userStream) async {
    try {
      // Build the .or() filter depending on whether the user's stream is known.
      // An empty stream value would produce a malformed filter like
      // `target_stream.eq.` (no value) → PostgREST PGRST100 error.
      final orFilter = userStream.isNotEmpty
          ? 'user_id.eq.$userId,'
              'and(user_id.is.null,target_stream.is.null),'
              'and(user_id.is.null,target_stream.eq.$userStream)'
          : 'user_id.eq.$userId,'
              'and(user_id.is.null,target_stream.is.null)';

      final rows = await _supabase
          .from('notifications')
          .select()
          .or(orFilter)
          .order('created_at', ascending: false)
          .limit(100);

      final db = await _db.database;
      final batch = db.batch();
      for (final row in rows) {
        final map = AppNotification.fromMap(row).toMap();
        map['user_id'] = userId;
        batch.insert(
          'notifications',
          map,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    } catch (e) {
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

  Future<void> markRead(int id) async {
    final db = await _db.database;
    await db.update(
      'notifications',
      {'is_read': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
    try {
      await _supabase.from('notifications').update({'is_read': true}).eq('id', id);
    } catch (_) {
      // Best-effort — local state already updated, remote sync can lag.
    }
  }

  Future<void> markAllRead(String userId) async {
    final db = await _db.database;
    await db.update(
      'notifications',
      {'is_read': 1},
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    try {
      await _supabase.from('notifications').update({'is_read': true}).eq('user_id', userId);
    } catch (_) {}
  }

  /// Inserts a notification locally immediately when a push arrives in the
  /// foreground — the bell/list updates without waiting for the next sync.
  Future<void> insertLocal(AppNotification n) async {
    final db = await _db.database;
    await db.insert(
      'notifications',
      n.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> saveFcmToken(String userId, String token) async {
    try {
      await _supabase.from('users').update({'fcm_token': token}).eq('id', userId);
    } catch (_) {
      // Non-fatal — token refresh will retry on next app open.
    }
  }
}
