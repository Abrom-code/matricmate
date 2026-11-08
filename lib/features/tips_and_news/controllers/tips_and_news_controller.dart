import 'package:get/get.dart';
import 'package:matricmate/data/repositories/tips_and_news/tips_and_news_repository.dart';
import 'package:matricmate/features/personalization/controllers/user_controller.dart';
import 'package:matricmate/features/tips_and_news/models/tips_and_news_model.dart';
import 'package:matricmate/utils/helpers/toast_helper.dart';

enum TipsNewsTab { all, news, tips }

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
  final RxInt unreadCount = 0.obs;
  final RxBool isLoading = false.obs;
  final RxBool isRefreshing = false.obs;
  final RxString searchQuery = ''.obs;

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

  /// Filtered items based on selected tab and search query
  List<TipsAndNewsModel> get filteredItems {
    Iterable<TipsAndNewsModel> list = allItems;

    // Tab filter
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

    // Search filter
    final query = searchQuery.value.trim().toLowerCase();
    if (query.isNotEmpty) {
      list = list.where(
        (item) =>
            item.title.toLowerCase().contains(query) ||
            item.content.toLowerCase().contains(query),
      );
    }

    return list.toList();
  }

  int get newsCount => allItems.where((i) => i.isNews).length;
  int get tipsCount => allItems.where((i) => i.isTip).length;

  void selectTab(TipsNewsTab tab) {
    selectedTab.value = tab;
  }

  void updateSearch(String val) {
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
  Future<void> syncRemote({bool isManual = false}) async {
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
      String? stream;
      if (Get.isRegistered<UserController>()) {
        stream = UserController.instance.user.value.stream;
      }

      final updated = await _repo.syncFromRemote(stream: stream);
      allItems.assignAll(updated);
      _lastSyncAt = DateTime.now();

      final count = await _repo.getUnreadCount();
      unreadCount.value = count;

      if (isManual) {
        ToastHelper.success('Updated tips & news');
      }
    } catch (_) {
      if (isManual) {
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
    if (idx != -1 && !allItems[idx].isRead) {
      allItems[idx] = allItems[idx].copyWith(isRead: true);
      allItems.refresh();
      unreadCount.value = (unreadCount.value - 1).clamp(0, 9999);
      await _repo.markAsRead(itemId);
    }
  }

  /// Marks all items as read locally.
  Future<void> markAllAsRead() async {
    final updated = allItems.map((i) => i.copyWith(isRead: true)).toList();
    allItems.assignAll(updated);
    unreadCount.value = 0;
    await _repo.markAllAsRead();
    ToastHelper.success('Marked all as read');
  }
}

