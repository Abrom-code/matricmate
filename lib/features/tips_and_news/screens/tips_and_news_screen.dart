import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:matricmate/common/widgets/appbar/reactive_refresh_button.dart';
import 'package:matricmate/common/widgets/loaders/circular_loading.dart';
import 'package:matricmate/features/tips_and_news/controllers/tips_and_news_controller.dart';
import 'package:matricmate/features/tips_and_news/screens/tips_and_news_detail_screen.dart';
import 'package:matricmate/features/tips_and_news/screens/widgets/tips_news_card.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

class TipsAndNewsScreen extends StatefulWidget {
  const TipsAndNewsScreen({super.key});

  @override
  State<TipsAndNewsScreen> createState() => _TipsAndNewsScreenState();
}

class _TipsAndNewsScreenState extends State<TipsAndNewsScreen> {
  late final TipsAndNewsController controller;
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    controller = TipsAndNewsController.instance;
  }

  void _openSearch() {
    setState(() => _isSearching = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _searchFocusNode.canRequestFocus) {
        _searchFocusNode.requestFocus();
      }
    });
  }

  void _closeSearch() {
    _searchFocusNode.unfocus();
    _searchCtrl.clear();
    controller.updateSearch('');
    setState(() => _isSearching = false);
  }

  @override
  void dispose() {
    _searchFocusNode.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = AppHelperFunctions.isDark(context);

    return Obx(() {
      final isSelecting = controller.isSelectionMode.value;

      return PopScope(
        canPop: !_isSearching && !isSelecting,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) return;
          if (isSelecting) {
            controller.exitSelectionMode();
            return;
          }
          if (_isSearching) {
            _closeSearch();
          }
        },
        child: Scaffold(
          backgroundColor: dark ? AppColors.dark : const Color(0xFFF8FAFC),
          appBar: isSelecting
              ? AppBar(
                  leading: IconButton(
                    icon: const Icon(Icons.close_rounded, size: 22),
                    tooltip: 'Cancel selection',
                    onPressed: controller.exitSelectionMode,
                  ),
                  title: Obx(() {
                    final count = controller.selectedIds.length;
                    return Text(
                      '$count selected',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    );
                  }),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.select_all_rounded, size: 22),
                      tooltip: 'Select all',
                      onPressed: () {
                        if (controller.selectedIds.length == controller.filteredItems.length) {
                          controller.deselectAll();
                        } else {
                          controller.selectAll();
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Iconsax.trash_copy, size: 21, color: Color(0xFFEF4444)),
                      tooltip: 'Delete selected',
                      onPressed: () => _confirmDeleteSelected(context),
                    ),
                    const SizedBox(width: 4),
                  ],
                )
              : AppBar(
                  titleSpacing: _isSearching ? 0 : null,
                  leading: _isSearching
                      ? IconButton(
                          icon: const Icon(Icons.arrow_back_rounded, size: 22),
                          tooltip: 'Close search',
                          onPressed: _closeSearch,
                        )
                      : null,
                  title: _isSearching
                      ? TextField(
                          focusNode: _searchFocusNode,
                          controller: _searchCtrl,
                          onChanged: controller.updateSearch,
                          textInputAction: TextInputAction.search,
                          style: TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w500,
                            color: dark ? Colors.white : AppColors.textPrimary,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Search tips & news...',
                            hintStyle: TextStyle(
                              fontSize: 14.5,
                              color: dark ? AppColors.darkGrey : AppColors.textSecondary,
                            ),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                            isDense: true,
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Tips & News',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            Obx(() {
                              final total = controller.allItems.length;
                              final unread = controller.unreadCount.value;
                              String sub = '$total updates';
                              if (unread > 0) {
                                sub += ' • $unread unread';
                              }
                              return Text(
                                sub,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: dark ? AppColors.darkGrey : AppColors.textSecondary,
                                ),
                              );
                            }),
                          ],
                        ),
                  actions: _isSearching
                      ? [
                          Obx(() {
                            if (controller.searchQuery.value.isEmpty) {
                              return const SizedBox.shrink();
                            }
                            return IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 20),
                              tooltip: 'Clear search',
                              onPressed: () {
                                _searchCtrl.clear();
                                controller.updateSearch('');
                              },
                            );
                          }),
                          const SizedBox(width: 4),
                        ]
                      : [
                          // Search button in AppBar
                          IconButton(
                            icon: const Icon(Iconsax.search_normal_1_copy, size: 20),
                            tooltip: 'Search',
                            onPressed: _openSearch,
                          ),

                          // Mark all read action (when unread items exist)
                          Obx(() {
                            if (controller.unreadCount.value == 0) {
                              return const SizedBox.shrink();
                            }
                            return IconButton(
                              icon: const Icon(Icons.done_all_rounded, size: 20),
                              tooltip: 'Mark all as read',
                              onPressed: () => controller.markAllAsRead(),
                            );
                          }),

                          // Refresh button with right-to-left rotation
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Obx(
                              () => ReactiveRefreshButton(
                                isRefreshing: controller.isRefreshing.value,
                                onRefresh: () => controller.syncRemote(isManual: true),
                                tooltip: 'Refresh',
                                onSuccessMessage: 'Tips & news updated',
                                counterClockwise: true,
                                color: dark ? Colors.white : AppColors.textPrimary,
                                backgroundColor: dark
                                    ? Colors.white.withValues(alpha: 0.12)
                                    : Colors.black.withValues(alpha: 0.05),
                              ),
                            ),
                          ),
                        ],
                ),
        body: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () => controller.syncRemote(isManual: true),
          child: Column(
            children: [
              // ── Tab Header ──────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                color: dark ? AppColors.darkCard : Colors.white,
                child: Obx(() {
                  final current = controller.selectedTab.value;
                  final total = controller.allItems.length;
                  final news = controller.newsCount;
                  final tips = controller.tipsCount;

                  return Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: dark ? AppColors.dark : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        _buildTabItem(
                          title: 'All',
                          count: total,
                          isSelected: current == TipsNewsTab.all,
                          dark: dark,
                          onTap: () => controller.selectTab(TipsNewsTab.all),
                        ),
                        _buildTabItem(
                          title: 'News',
                          count: news,
                          isSelected: current == TipsNewsTab.news,
                          dark: dark,
                          onTap: () => controller.selectTab(TipsNewsTab.news),
                        ),
                        _buildTabItem(
                          title: 'Tips',
                          count: tips,
                          isSelected: current == TipsNewsTab.tips,
                          dark: dark,
                          onTap: () => controller.selectTab(TipsNewsTab.tips),
                        ),
                      ],
                    ),
                  );
                }),
              ),

              // ── Quick Sub-Filter Chips (All, Saved, Unread) ──────────────
              Container(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                color: dark ? AppColors.darkCard : Colors.white,
                child: Obx(() {
                  final activeSub = controller.subFilter.value;
                  final savedTotal = controller.savedCount;
                  final unreadTotal = controller.unreadCount.value;

                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildSubFilterChip(
                          label: 'All Items',
                          icon: null,
                          isSelected: activeSub == TipsNewsSubFilter.all,
                          dark: dark,
                          onTap: () =>
                              controller.selectSubFilter(TipsNewsSubFilter.all),
                        ),
                        const SizedBox(width: 8),
                        _buildSubFilterChip(
                          label: 'Saved',
                          icon: Icons.bookmark_rounded,
                          count: savedTotal,
                          isSelected: activeSub == TipsNewsSubFilter.saved,
                          dark: dark,
                          activeColor: const Color(0xFFF59E0B),
                          onTap: () => controller
                              .selectSubFilter(TipsNewsSubFilter.saved),
                        ),
                        const SizedBox(width: 8),
                        _buildSubFilterChip(
                          label: 'Unread',
                          icon: Icons.circle,
                          iconSize: 7,
                          count: unreadTotal,
                          isSelected: activeSub == TipsNewsSubFilter.unread,
                          dark: dark,
                          activeColor: const Color(0xFFEF4444),
                          onTap: () => controller
                              .selectSubFilter(TipsNewsSubFilter.unread),
                        ),
                      ],
                    ),
                  );
                }),
              ),

              const SizedBox(height: 6),

              // ── Feed List View ──────────────────────────────────────────────
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value && controller.allItems.isEmpty) {
                  return const Center(child: AppCircularLoading());
                }

                final items = controller.filteredItems;

                if (items.isEmpty) {
                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
                    children: [
                      Center(
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: (dark ? Colors.white10 : const Color(0xFFF1F5F9)),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                controller.subFilter.value == TipsNewsSubFilter.saved
                                    ? Icons.bookmark_border_rounded
                                    : controller.selectedTab.value == TipsNewsTab.tips
                                        ? Iconsax.lamp_on_copy
                                        : Iconsax.volume_high_copy,
                                size: 38,
                                color: dark ? AppColors.darkGrey : AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              controller.searchQuery.value.isNotEmpty
                                  ? 'No matching results found'
                                  : controller.subFilter.value == TipsNewsSubFilter.saved
                                      ? 'No saved items yet'
                                      : controller.subFilter.value == TipsNewsSubFilter.unread
                                          ? 'All caught up! No unread updates'
                                          : 'No ${controller.selectedTab.value == TipsNewsTab.tips ? 'tips' : controller.selectedTab.value == TipsNewsTab.news ? 'news' : 'updates'} yet',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: dark ? Colors.white : AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              controller.searchQuery.value.isNotEmpty
                                  ? 'Try adjusting your search terms'
                                  : controller.subFilter.value == TipsNewsSubFilter.saved
                                      ? 'Tap the bookmark icon on any tip or news to save it here for quick review.'
                                      : 'Check back soon! New tips and news will appear here when published.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: dark ? AppColors.darkGrey : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }

                // Split sections for 'All' sub-filter with no search
                final hasSplit = controller.subFilter.value == TipsNewsSubFilter.all &&
                    controller.searchQuery.value.isEmpty &&
                    controller.pinnedSectionItems.isNotEmpty &&
                    controller.recentSectionItems.isNotEmpty;

                if (hasSplit) {
                  final pinned = controller.pinnedSectionItems;
                  final recentAll = controller.recentSectionItems;
                  final recentPaginated = controller.paginatedRecentSectionItems;
                  final hasMore = controller.hasMoreRecentItems;

                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    children: [
                      _buildSectionHeader(
                        title: 'Pinned Announcements',
                        icon: Icons.push_pin_rounded,
                        color: AppColors.primary,
                        count: pinned.length,
                        dark: dark,
                      ),
                      ...pinned.map(
                        (item) => TipsNewsCard(
                          key: ValueKey('tips_news_${item.id}_${item.isRead}_${item.isUserPinned}_${controller.selectedIds.contains(item.id)}'),
                          item: item,
                          isSelectionMode: isSelecting,
                          isSelected: controller.selectedIds.contains(item.id),
                          onPinToggle: () => controller.toggleSave(item.id),
                          onLongPress: () {
                            if (!isSelecting) controller.startSelection(item.id);
                          },
                          onTap: () async {
                            if (isSelecting) {
                              controller.toggleSelection(item.id);
                            } else {
                              controller.markAsRead(item.id);
                              await Get.to(
                                () => TipsAndNewsDetailScreen(
                                  item: item.copyWith(isRead: true),
                                ),
                              );
                              controller.loadLocalData();
                            }
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildSectionHeader(
                        title: 'Recent Updates',
                        icon: Icons.schedule_rounded,
                        color: AppColors.primary,
                        count: recentAll.length,
                        dark: dark,
                      ),
                      ...recentPaginated.map(
                        (item) => TipsNewsCard(
                          key: ValueKey('tips_news_${item.id}_${item.isRead}_${item.isUserPinned}_${controller.selectedIds.contains(item.id)}'),
                          item: item,
                          isSelectionMode: isSelecting,
                          isSelected: controller.selectedIds.contains(item.id),
                          onPinToggle: () => controller.toggleSave(item.id),
                          onLongPress: () {
                            if (!isSelecting) controller.startSelection(item.id);
                          },
                          onTap: () async {
                            if (isSelecting) {
                              controller.toggleSelection(item.id);
                            } else {
                              controller.markAsRead(item.id);
                              await Get.to(
                                () => TipsAndNewsDetailScreen(
                                  item: item.copyWith(isRead: true),
                                ),
                              );
                              controller.loadLocalData();
                            }
                          },
                        ),
                      ),
                      if (hasMore)
                        _buildLoadMoreFooter(
                          onLoadMore: () => controller.loadMore(),
                          remaining: controller.remainingRecentCount,
                          total: recentAll.length,
                          showing: recentPaginated.length,
                          dark: dark,
                        )
                      else if (recentAll.length > TipsAndNewsController.pageSize)
                        _buildCaughtUpFooter(recentAll.length, dark),
                    ],
                  );
                }

                final paginated = controller.paginatedItems;
                final hasMore = controller.hasMoreItems;
                final itemCount = paginated.length + (hasMore || items.length > TipsAndNewsController.pageSize ? 1 : 0);

                return ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: itemCount,
                  itemBuilder: (context, index) {
                    if (index == paginated.length) {
                      if (hasMore) {
                        return _buildLoadMoreFooter(
                          onLoadMore: () => controller.loadMore(),
                          remaining: controller.remainingCount,
                          total: items.length,
                          showing: paginated.length,
                          dark: dark,
                        );
                      } else {
                        return _buildCaughtUpFooter(items.length, dark);
                      }
                    }

                    final item = paginated[index];
                    return TipsNewsCard(
                      key: ValueKey('tips_news_${item.id}_${item.isRead}_${item.isUserPinned}_${controller.selectedIds.contains(item.id)}'),
                      item: item,
                      isSelectionMode: isSelecting,
                      isSelected: controller.selectedIds.contains(item.id),
                      onPinToggle: () => controller.toggleSave(item.id),
                      onLongPress: () {
                        if (!isSelecting) controller.startSelection(item.id);
                      },
                      onTap: () async {
                        if (isSelecting) {
                          controller.toggleSelection(item.id);
                        } else {
                          controller.markAsRead(item.id);
                          await Get.to(
                            () => TipsAndNewsDetailScreen(
                              item: item.copyWith(isRead: true),
                            ),
                          );
                          controller.loadLocalData();
                        }
                      },
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    ),
  );
});
}

  Future<void> _confirmDeleteSelected(BuildContext context) async {
    final count = controller.selectedIds.length;
    if (count == 0) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete $count update${count > 1 ? 's' : ''}?'),
        content: const Text(
          'Selected updates will be removed from your device and will not appear again even after refreshing.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFEF4444),
            ),
            child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await controller.deleteSelected();
    }
  }

  Widget _buildTabItem({
    required String title,
    required int count,
    required bool isSelected,
    required bool dark,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? (dark ? const Color(0xFF262626) : Colors.white)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: dark ? 0.3 : 0.06),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? AppColors.primary
                      : (dark ? AppColors.darkGrey : AppColors.textSecondary),
                ),
              ),
              if (count > 0) ...[
                const SizedBox(width: 5),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withValues(alpha: 0.15)
                        : (dark ? Colors.white10 : const Color(0xFFE2E8F0)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? AppColors.primary
                          : (dark ? AppColors.darkGrey : AppColors.textSecondary),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubFilterChip({
    required String label,
    IconData? icon,
    double iconSize = 13,
    int? count,
    required bool isSelected,
    required bool dark,
    Color? activeColor,
    required VoidCallback onTap,
  }) {
    final effectiveColor = activeColor ?? AppColors.primary;
    final bg = isSelected
        ? effectiveColor.withValues(alpha: dark ? 0.22 : 0.12)
        : (dark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9));
    final fg = isSelected
        ? effectiveColor
        : (dark ? AppColors.darkGrey : AppColors.textSecondary);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? effectiveColor.withValues(alpha: 0.45)
                  : Colors.transparent,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: iconSize, color: fg),
                const SizedBox(width: 5),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: fg,
                ),
              ),
              if (count != null && count > 0) ...[
                const SizedBox(width: 5),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? effectiveColor.withValues(alpha: 0.2)
                        : (dark ? Colors.white10 : const Color(0xFFE2E8F0)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: fg,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required IconData icon,
    required Color color,
    required int count,
    required bool dark,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.7,
              color: dark ? AppColors.darkGrey : AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
            decoration: BoxDecoration(
              color: color.withValues(alpha: dark ? 0.2 : 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadMoreFooter({
    required VoidCallback onLoadMore,
    required int remaining,
    required int total,
    required int showing,
    required bool dark,
  }) {
    return Container(
      margin: const EdgeInsets.only(top: 6, bottom: 24),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: dark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: dark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        children: [
          Text(
            'Showing $showing of $total updates',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: dark ? AppColors.darkGrey : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                HapticFeedback.lightImpact();
                onLoadMore();
              },
              icon: const Icon(Icons.arrow_downward_rounded, size: 16),
              label: Text(
                'Load Earlier Updates ($remaining remaining)',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: BorderSide(color: AppColors.primary.withValues(alpha: 0.5)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 11),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCaughtUpFooter(int total, bool dark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle_outline_rounded,
              size: 15,
              color: dark ? AppColors.darkGrey : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              "You're all caught up ($total updates)",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: dark ? AppColors.darkGrey : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

