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

  // ── Multi-selection state ───────────────────────────────────────────
  final RxSet<int> selectedIds = <int>{}.obs;
  bool get isSelectionMode => selectedIds.isNotEmpty;

  // ── Undo snapshots ──────────────────────────────────────────────────
  AppNotification? _lastDeletedOne;
  int? _lastDeletedOneIndex;
  List<AppNotification>? _lastDeletedAll;
  List<AppNotification>? _lastDeletedSelected;
  Map<int, int>? _lastDeletedSelectedIndexes;

  String get _userId => UserController.instance.user.value.id;
  String get _userStream => UserController.instance.user.value.stream;

  @override
  void onInit() {
    super.onInit();
    // Load local notifications immediately for responsive bell badge
    ever(UserController.instance.user, (_) {
      if (_userId.isNotEmpty) loadNotifications();
    });
  }

  /// Loads notifications from local SQLite and optionally syncs from remote.
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
      debugPrint(
        '[Notifications] userId still empty after wait — aborting load',
      );
      return;
    }

    try {
      isLoading.value = true;
      debugPrint(
        '[Notifications] loadNotifications userId=$_userId syncRemote=$syncRemote',
      );

      if (syncRemote) {
        try {
          final signupAt = UserController.instance.user.value.createdAt;
          await _repo.syncFromRemote(_userId, _userStream, signupAt: signupAt);
        } catch (e) {
          debugPrint('[Notifications] syncFromRemote failed: $e');
        }
      }

      notifications.assignAll(await _repo.getLocal(_userId));
      _recalcUnread();
      debugPrint(
        '[Notifications] loaded ${notifications.length} notifications, ${unreadCount.value} unread',
      );
    } catch (e) {
      AppExceptionHandler.handleResponse(e);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> markRead(int id) async {
    // Optimistic: update in-memory list immediately.
    final idx = notifications.indexWhere((n) => n.id == id);
    if (idx != -1 && !notifications[idx].isRead) {
      notifications[idx] = notifications[idx].copyWith(isRead: true);
      notifications.refresh();
      _recalcUnread();
    }
    await _repo.markRead(id);
  }

  Future<void> markAllRead() async {
    if (_userId.isEmpty) return;
    // Optimistic: mark everything read in memory.
    for (int i = 0; i < notifications.length; i++) {
      if (!notifications[i].isRead) {
        notifications[i] = notifications[i].copyWith(isRead: true);
      }
    }
    notifications.refresh();
    _recalcUnread();
    await _repo.markAllRead(_userId);
  }

  Future<void> insertFromPush(AppNotification n) async {
    await _repo.insertLocal(n);
    await loadNotifications();
  }

  // ── Optimistic single-delete with undo ──────────────────────────────

  /// Optimistically deletes a single notification with undo capability.
  Future<void> deleteOne(int id) async {
    final index = notifications.indexWhere((n) => n.id == id);
    if (index == -1) return;

    // Snapshot for undo.
    _lastDeletedOne = notifications[index];
    _lastDeletedOneIndex = index;

    // Remove from in-memory list immediately.
    notifications.removeAt(index);
    _recalcUnread();

    // Persist deletion in the background.
    await _repo.deleteNotification(_lastDeletedOne!);
  }

  /// Restores the last single-deleted notification (called from "Undo" SnackBar).
  Future<void> undoDeleteOne() async {
    final item = _lastDeletedOne;
    final index = _lastDeletedOneIndex;
    if (item == null || index == null) return;

    // Re-insert locally (repo will handle SQLite + clearing dismissal).
    await _repo.insertLocal(item);

    // Restore to in-memory list at the original position.
    final clampedIndex = index.clamp(0, notifications.length);
    notifications.insert(clampedIndex, item);
    _recalcUnread();

    _lastDeletedOne = null;
    _lastDeletedOneIndex = null;
  }

  // ── Optimistic bulk-delete with undo ────────────────────────────────

  /// Optimistically deletes all notifications with undo capability.
  Future<void> deleteAll() async {
    if (_userId.isEmpty) return;

    // Snapshot for undo.
    _lastDeletedAll = notifications.toList();

    // Clear in-memory list immediately.
    notifications.clear();
    _recalcUnread();

    // Persist deletion in the background.
    await _repo.deleteAllNotifications(_userId, _lastDeletedAll!);
  }

  /// Restores all deleted notifications (called from "Undo" SnackBar).
  Future<void> undoDeleteAll() async {
    final items = _lastDeletedAll;
    if (items == null || items.isEmpty) return;

    // Re-insert all locally.
    for (final item in items) {
      await _repo.insertLocal(item);
    }

    notifications.assignAll(items);
    _recalcUnread();

    _lastDeletedAll = null;
  }

  // ── Multi-selection actions ─────────────────────────────────────────

  void toggleSelection(int id) {
    if (selectedIds.contains(id)) {
      selectedIds.remove(id);
    } else {
      selectedIds.add(id);
    }
  }

  void selectAll() {
    selectedIds.assignAll(notifications.map((n) => n.id));
  }

  void clearSelection() {
    selectedIds.clear();
  }

  Future<void> markSelectedAsRead() async {
    if (selectedIds.isEmpty) return;

    final targetIds = selectedIds.toSet();
    for (int i = 0; i < notifications.length; i++) {
      if (targetIds.contains(notifications[i].id) && !notifications[i].isRead) {
        notifications[i] = notifications[i].copyWith(isRead: true);
      }
    }
    notifications.refresh();
    _recalcUnread();
    clearSelection();

    // Persist to server & local DB
    for (final id in targetIds) {
      await _repo.markRead(id);
    }
  }

  /// Optimistically deletes all currently selected notifications with undo.
  Future<void> deleteSelected() async {
    if (selectedIds.isEmpty) return;

    final targetIds = selectedIds.toSet();
    _lastDeletedSelected = notifications.where((n) => targetIds.contains(n.id)).toList();
    _lastDeletedSelectedIndexes = {
      for (int i = 0; i < notifications.length; i++)
        if (targetIds.contains(notifications[i].id)) notifications[i].id: i,
    };

    // Remove from in-memory list immediately
    notifications.removeWhere((n) => targetIds.contains(n.id));
    _recalcUnread();
    clearSelection();

    // Persist deletion in background
    for (final item in _lastDeletedSelected!) {
      await _repo.deleteNotification(item);
    }
  }

  /// Restores multi-selected deleted notifications (called from "Undo" SnackBar).
  Future<void> undoDeleteSelected() async {
    final items = _lastDeletedSelected;
    final indexes = _lastDeletedSelectedIndexes;
    if (items == null || items.isEmpty) return;

    for (final item in items) {
      await _repo.insertLocal(item);
      final originalIndex = indexes?[item.id] ?? notifications.length;
      final clampedIndex = originalIndex.clamp(0, notifications.length);
      notifications.insert(clampedIndex, item);
    }

    _recalcUnread();
    _lastDeletedSelected = null;
    _lastDeletedSelectedIndexes = null;
  }

  /// Recalculates unread count from the in-memory list.
  void _recalcUnread() {
    unreadCount.value = notifications.where((n) => !n.isRead).length;
  }

  /// Diagnostic query directly from Supabase for debugging.
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
        debugPrint(
          '  id=${r['id']} user_id=${r['user_id']} '
          'title=${r['title']} type=${r['type']}',
        );
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
