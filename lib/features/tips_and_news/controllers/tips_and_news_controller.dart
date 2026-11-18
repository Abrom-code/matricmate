import 'package:get/get.dart';
import 'package:matricmate/data/repositories/tips_and_news/tips_and_news_repository.dart';
import 'package:matricmate/features/tips_and_news/models/tips_and_news_model.dart';
import 'package:matricmate/utils/helpers/toast_helper.dart';

enum TipsNewsTab { all, news, tips }

enum TipsNewsSubFilter { all, saved, unread }

class TipsAndNewsController extends GetxController {
  static TipsAndNewsController get instance {
    if (Get.isRegistered<TipsAndNewsController>()) {
      return Get.find<TipsAndNewsController>();
    }
    return Get.put(TipsAndNewsController(), permanent: true);
  }

  final TipsAndNewsRepository _repo = TipsAndNewsRepository();

  final RxList<TipsAndNewsModel> allItems = <TipsAndNewsModel>[].obs;
  final Rx<TipsNewsTab> selectedTab = TipsNewsTab.all.obs;
  final Rx<TipsNewsSubFilter> subFilter = TipsNewsSubFilter.all.obs;
  final RxInt unreadCount = 0.obs;
  final RxBool isLoading = false.obs;
  final RxBool isRefreshing = false.obs;
  final RxString searchQuery = ''.obs;

  /// Multi-selection mode for batch deletion
  final RxBool isSelectionMode = false.obs;
  final RxSet<int> selectedIds = <int>{}.obs;

  /// Number of items to display initially before showing 'Load More'
  static const int pageSize = 15;
  final RxInt displayLimit = pageSize.obs;

  bool get hasUnread => unreadCount.value > 0;

  DateTime _lastSyncAt = DateTime(2000);
  static const _syncCooldown = Duration(seconds: 45);

  @override
  void onInit() {
    super.onInit();
    // 1. Instant local load
    loadLocalData();
    // 2. Fetch remote updates in background
    syncRemote();
  }

  /// Filtered items based on selected tab, subFilter, and search query.
  List<TipsAndNewsModel> get filteredItems {
    Iterable<TipsAndNewsModel> list = allItems;

    // 1. Tab filter
    switch (selectedTab.value) {
      case TipsNewsTab.news:
        list = list.where((item) => item.isNews);
        break;
      case TipsNewsTab.tips:
        list = list.where((item) => item.isTip);
        break;
      case TipsNewsTab.all:
        break;
    }

    // 2. Sub-filter (All, Saved, Unread)
    switch (subFilter.value) {
      case TipsNewsSubFilter.saved:
        list = list.where((item) => item.isSaved);
        break;
      case TipsNewsSubFilter.unread:
        list = list.where((item) => !item.isRead);
        break;
      case TipsNewsSubFilter.all:
        break;
    }

    // 3. Search filter
    final query = searchQuery.value.trim().toLowerCase();
    if (query.isNotEmpty) {
      list = list.where(
        (item) =>
            item.title.toLowerCase().contains(query) ||
            item.content.toLowerCase().contains(query),
      );
    }

    // 4. Stable sort: Admin Pinned first, then User Saved, then latest
    final sorted = list.toList()
      ..sort((a, b) {
        final aPinned = a.isPinned ? 2 : (a.isSaved ? 1 : 0);
        final bPinned = b.isPinned ? 2 : (b.isSaved ? 1 : 0);
        if (aPinned != bPinned) return bPinned.compareTo(aPinned);
        return b.createdAt.compareTo(a.createdAt);
      });

    return sorted;
  }

  /// Sliced items for display based on current pagination limit
  List<TipsAndNewsModel> get paginatedItems {
    final all = filteredItems;
    if (all.length <= displayLimit.value) return all;
    return all.take(displayLimit.value).toList();
  }

  /// Admin-pinned announcements for the top section
  List<TipsAndNewsModel> get pinnedSectionItems =>
      filteredItems.where((i) => i.isPinned).toList();

  /// Regular stream items
  List<TipsAndNewsModel> get recentSectionItems =>
      filteredItems.where((i) => !i.isPinned).toList();

  /// Paginated recent items for split view
  List<TipsAndNewsModel> get paginatedRecentSectionItems {
    final recent = recentSectionItems;
    if (recent.length <= displayLimit.value) return recent;
    return recent.take(displayLimit.value).toList();
  }

  bool get hasMoreItems => filteredItems.length > displayLimit.value;
  int get remainingCount =>
      (filteredItems.length - displayLimit.value).clamp(0, 9999);

  bool get hasMoreRecentItems =>
      recentSectionItems.length > displayLimit.value;
  int get remainingRecentCount =>
      (recentSectionItems.length - displayLimit.value).clamp(0, 9999);

  void loadMore() {
    displayLimit.value += pageSize;
  }

  int get newsCount => allItems.where((i) => i.isNews).length;
  int get tipsCount => allItems.where((i) => i.isTip).length;
  int get adminPinnedCount => allItems.where((i) => i.isPinned).length;
  int get savedCount => allItems.where((i) => i.isSaved).length;
  int get unreadItemsCount => allItems.where((i) => !i.isRead).length;

  void selectTab(TipsNewsTab tab) {
    displayLimit.value = pageSize;
    selectedTab.value = tab;
  }

  void selectSubFilter(TipsNewsSubFilter filter) {
    displayLimit.value = pageSize;
    subFilter.value = filter;
  }

  void updateSearch(String val) {
    displayLimit.value = pageSize;
    searchQuery.value = val;
  }

  /// Instant display from local SQLite (0 network latency)
  Future<void> loadLocalData() async {
    try {
      final local = await _repo.getLocalItems();
      allItems.assignAll(local);
      final count = await _repo.getUnreadCount();
      unreadCount.value = count;
    } catch (_) {}
  }

  /// Remote delta sync
  Future<void> syncRemote({
    bool isManual = false,
    bool showToast = false,
  }) async {
    final now = DateTime.now();
    if (!isManual && now.difference(_lastSyncAt) < _syncCooldown) {
      return;
    }

    if (isManual) {
      isRefreshing.value = true;
    } else if (allItems.isEmpty) {
      isLoading.value = true;
    }

    try {
      final updated = await _repo.syncFromRemote();
      allItems.assignAll(updated);
      _lastSyncAt = DateTime.now();

      final count = await _repo.getUnreadCount();
      unreadCount.value = count;

      if (showToast) {
        ToastHelper.success('Updated tips & news');
      }
    } catch (_) {
      if (showToast) {
        ToastHelper.warning('Could not refresh. Showing offline content.');
      }
    } finally {
      isLoading.value = false;
      isRefreshing.value = false;
    }
  }

  /// Marks a single item as read locally.
  Future<void> markAsRead(int itemId) async {
    final idx = allItems.indexWhere((i) => i.id == itemId);
    if (idx != -1) {
      if (!allItems[idx].isRead) {
        allItems[idx] = allItems[idx].copyWith(isRead: true);
        allItems.refresh();
        unreadCount.value = (unreadCount.value - 1).clamp(0, 9999);
      }
    }
    await _repo.markAsRead(itemId);
  }

  /// Marks all items as read locally.
  Future<void> markAllAsRead() async {
    final updated = allItems.map((i) => i.copyWith(isRead: true)).toList();
    allItems.assignAll(updated);
    unreadCount.value = 0;
    await _repo.markAllAsRead();
    ToastHelper.success('Marked all as read');
  }

  /// Toggles personal saved/bookmark status for an item (0ms, 100% local SQLite).
  Future<void> toggleSave(int itemId) async {
    final idx = allItems.indexWhere((i) => i.id == itemId);
    if (idx != -1) {
      final currentSaved = allItems[idx].isSaved;
      final newSaved = !currentSaved;
      allItems[idx] = allItems[idx].copyWith(isUserPinned: newSaved);
      allItems.refresh();

      final isSavedNow = await _repo.toggleUserPin(itemId);
      if (isSavedNow) {
        ToastHelper.success('Saved to bookmarks');
      } else {
        ToastHelper.success('Removed from saved');
      }
    } else {
      await _repo.toggleUserPin(itemId);
    }
  }

  /// Backward-compatible alias
  Future<void> toggleUserPin(int itemId) => toggleSave(itemId);

  // ── Multi-Selection & Deletion Helpers ─────────────────────────────────────

  void startSelection(int initialId) {
    isSelectionMode.value = true;
    selectedIds.clear();
    selectedIds.add(initialId);
  }

  void toggleSelection(int id) {
    if (selectedIds.contains(id)) {
      selectedIds.remove(id);
      if (selectedIds.isEmpty) {
        exitSelectionMode();
      }
    } else {
      selectedIds.add(id);
    }
  }

  void selectAll() {
    selectedIds.addAll(filteredItems.map((i) => i.id));
  }

  void deselectAll() {
    selectedIds.clear();
  }

  void exitSelectionMode() {
    isSelectionMode.value = false;
    selectedIds.clear();
  }

  /// Deletes selected items locally and registers tombstones so refresh never re-inserts them.
  Future<void> deleteSelected() async {
    final ids = selectedIds.toList();
    if (ids.isEmpty) return;

    // Immediately remove from UI
    allItems.removeWhere((i) => ids.contains(i.id));
    exitSelectionMode();

    final unread = await _repo.getUnreadCount();
    unreadCount.value = unread;
    await _repo.deleteItems(ids);
    ToastHelper.success('${ids.length} item(s) deleted');
  }

  /// Deletes a single item locally and registers a tombstone so refresh never re-inserts it.
  Future<void> deleteSingle(int id) async {
    allItems.removeWhere((i) => i.id == id);
    if (selectedIds.contains(id)) {
      selectedIds.remove(id);
      if (selectedIds.isEmpty) exitSelectionMode();
    }
    final unread = await _repo.getUnreadCount();
    unreadCount.value = unread;
    await _repo.deleteItems([id]);
    ToastHelper.success('Item deleted');
  }
}

