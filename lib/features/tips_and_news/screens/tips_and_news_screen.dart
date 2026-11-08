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

    return PopScope(
      canPop: !_isSearching,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_isSearching) {
          _closeSearch();
        }
      },
      child: Scaffold(
        backgroundColor: dark ? AppColors.dark : const Color(0xFFF8FAFC),
        appBar: AppBar(
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
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
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

              const SizedBox(height: 8),

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
                                controller.selectedTab.value == TipsNewsTab.tips
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

                return ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return TipsNewsCard(
                      key: ValueKey('tips_news_${item.id}_${item.isRead}'),
                      item: item,
                      onTap: () async {
                        controller.markAsRead(item.id);
                        await Get.to(
                          () => TipsAndNewsDetailScreen(
                            item: item.copyWith(isRead: true),
                          ),
                        );
                        controller.loadLocalData();
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
}

