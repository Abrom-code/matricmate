import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:matricmate/data/repositories/notifications/notification_repository.dart';
import 'package:matricmate/data/services/ensure_supabase_auth.dart';
import 'package:matricmate/features/notifications/models/notification_model.dart';
import 'package:matricmate/features/personalization/controllers/user_controller.dart';
import 'package:matricmate/utils/exceptions/exception_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationsController extends GetxController {
  static NotificationsController get instance => Get.find();

  final NotificationRepository _repo = NotificationRepository();

  final RxList<AppNotification> notifications = <AppNotification>[].obs;
  final RxInt unreadCount = 0.obs;
  final RxBool isLoading = false.obs;

  String get _userId => UserController.instance.user.value.id;
  String get _userStream => UserController.instance.user.value.stream;

  /// Loads notifications. If [syncRemote] is true, pulls from Supabase first.
  /// Guards against empty userId — safe to call before user fully loads.
  Future<void> loadNotifications({bool syncRemote = false}) async {
    // Wait up to 3 s for userId to be populated if called too early.
    if (_userId.isEmpty) {
      debugPrint('[Notifications] userId empty — waiting for user to load...');
      for (int i = 0; i < 30; i++) {
        await Future.delayed(const Duration(milliseconds: 100));
        if (_userId.isNotEmpty) break;
      }
    }

    if (_userId.isEmpty) {
      debugPrint('[Notifications] userId still empty after wait — aborting load');
      return;
    }

    try {
      isLoading.value = true;
      debugPrint('[Notifications] loadNotifications userId=$_userId syncRemote=$syncRemote');

      if (syncRemote) {
        try {
          await _repo.syncFromRemote(_userId, _userStream);
        } catch (e) {
          debugPrint('[Notifications] syncFromRemote failed: $e');
        }
      }

      notifications.assignAll(await _repo.getLocal(_userId));
      unreadCount.value = await _repo.getUnreadCount(_userId);
      debugPrint('[Notifications] loaded ${notifications.length} notifications, ${unreadCount.value} unread');
    } catch (e) {
      AppExceptionHandler.handleResponse(e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> markRead(int id) async {
    await _repo.markRead(id);
    await loadNotifications();
  }

  Future<void> markAllRead() async {
    if (_userId.isEmpty) return;
    await _repo.markAllRead(_userId);
    await loadNotifications();
  }

  Future<void> insertFromPush(AppNotification n) async {
    await _repo.insertLocal(n);
    await loadNotifications();
  }

  // ── Diagnostic: call from notifications screen pull-to-refresh ──────
  /// Queries Supabase directly (bypasses SQLite) and prints every row found.
  /// Run in debug mode and watch the console to verify what's in the DB.
  Future<void> diagnose() async {
    debugPrint('══════════════ [Notifications Diagnose] ══════════════');
    debugPrint('userId  = $_userId');
    debugPrint('stream  = $_userStream');

    if (_userId.isEmpty) {
      debugPrint('ERROR: userId is empty — user not loaded yet');
      debugPrint('══════════════════════════════════════════════════════');
      return;
    }

    try {
      await ensureSupabaseAuth();
      final client = Supabase.instance.client;

      // 1. All rows in notifications table (no filter — see everything)
      final all = await client
          .from('notifications')
          .select('id, user_id, title, type, created_at')
          .order('created_at', ascending: false)
          .limit(20);

      debugPrint('Total rows in notifications (limit 20): ${all.length}');
      for (final r in all) {
        debugPrint('  id=${r['id']} user_id=${r['user_id']} '
            'title=${r['title']} type=${r['type']}');
      }

      // 2. Rows for this user specifically
      final personal = await client
          .from('notifications')
          .select('id, title, type')
          .eq('user_id', _userId);
      debugPrint('Personal rows (user_id=$_userId): ${personal.length}');

      // 3. Broadcast rows
      final broadcast = await client
          .from('notifications')
          .select('id, title, type, target_stream')
          .isFilter('user_id', null);
      debugPrint('Broadcast rows (user_id IS NULL): ${broadcast.length}');

      // 4. Local SQLite count
      final local = await _repo.getLocal(_userId);
      debugPrint('Local SQLite rows for this user: ${local.length}');

    } catch (e, st) {
      debugPrint('ERROR during diagnose: $e\n$st');
    }

    debugPrint('══════════════════════════════════════════════════════');
  }
}
