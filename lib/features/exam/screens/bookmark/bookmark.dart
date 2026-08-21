import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:matricmate/common/widgets/appbar/modern_appbar.dart';
import 'package:matricmate/common/widgets/loaders/circular_loading.dart';
import 'package:matricmate/features/exam/controllers/bookmark_controller.dart';
import 'package:matricmate/features/exam/screens/bookmark/widgets/bookmark_container.dart';
import 'package:matricmate/routes/app_routes.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/constants/sizes.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

class BookmarkScreen extends StatefulWidget {
  BookmarkScreen({super.key});

  @override
  State<BookmarkScreen> createState() => _BookmarkScreenState();
}

class _BookmarkScreenState extends State<BookmarkScreen>
    with SingleTickerProviderStateMixin, RouteAware {
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  bool _searchVisible = false;

  BookmarkController get ctrl => BookmarkController.instance;

  @override
  void initState() {
    super.initState();
    ctrl.clearSearch();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Subscribe using the NavigationMenu's route (the route this PageView lives in)
    final route = ModalRoute.of(context);
    if (route != null) {
      appRouteObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    appRouteObserver.unsubscribe(this);
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  /// Collapses search bar when a new route is pushed over navigation menu.
  @override
  void didPushNext() {
    if (_searchVisible) {
      setState(() {
        _searchVisible = false;
      });
    }
    _searchFocus.unfocus();
    _searchController.clear();
    ctrl.clearSearch();
  }

  void _toggleSearch() {
    setState(() {
      _searchVisible = !_searchVisible;
      if (!_searchVisible) {
        _clearSearch();
      } else {
        // Auto-focus after the animation frame
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _searchFocus.requestFocus(),
        );
      }
    });
  }

  void _clearSearch() {
    _searchController.clear();
    ctrl.clearSearch();
    _searchFocus.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final dark = AppHelperFunctions.isDark(context);

    return Scaffold(
      appBar: ModernAppbarWithBuilder(
        title: 'Bookmarks',
        subtitleBuilder: (_) => Obx(() {
          final count = ctrl.bookmarkedQuestions.length;
          return Text(
            '$count ${count == 1 ? 'item' : 'items'} saved',
            style: const TextStyle(
              color: Color(0xFFD1FAE5),
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
            ),
          );
        }),
        actions: [
          IconButton(
            tooltip: _searchVisible ? 'Close search' : 'Search bookmarks',
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.all(0),
            onPressed: _toggleSearch,
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                _searchVisible ? Icons.close : Iconsax.search_normal_1_copy,
                key: ValueKey(_searchVisible),
                size: 20,
                color: AppColors.white,
              ),
            ),
          ),
        ],
      ),
      body: Obx(() {
        if (ctrl.isLoading.value && ctrl.bookmarkedQuestions.isEmpty) {
          return const AppCircularLoading(title: 'Loading...');
        }

        final tabs = ctrl.subjects;

        return DefaultTabController(
          key: ValueKey(tabs.length),
          length: tabs.length,
          child: Column(
            children: [
              // ── Animated search bar ─────────────────────────────────
              AnimatedSize(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                child: _searchVisible
                    ? _SearchBar(
                        controller: _searchController,
                        focusNode: _searchFocus,
                        dark: dark,
                        onChanged: (v) => ctrl.searchQuery.value = v,
                        onClear: _clearSearch,
                      )
                    : const SizedBox.shrink(),
              ),

              // ── Tab bar ─────────────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: dark ? AppColors.darkCard : AppColors.white,
                  border: Border(
                    bottom: BorderSide(
                      color: dark
                          ? AppColors.darkBorder
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                ),
                child: TabBar(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  indicator: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelColor: AppColors.white,
                  unselectedLabelColor: dark
                      ? AppColors.darkGrey
                      : AppColors.textSecondary,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                  tabs: tabs.map((t) {
                    final count = ctrl.getBySubject(t).length;
                    return Tab(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Text(
                          t == 'All' || count == 0 ? t : '$t ($count)',
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              // ── Tab content ─────────────────────────────────────────
              Expanded(
                child: TabBarView(
                  children: tabs.map((subject) {
                    final filtered = ctrl.getBySubject(subject);
                    if (filtered.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(
                                    alpha: dark ? 0.2 : 0.08,
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.bookmark_border_rounded,
                                    size: 36,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No bookmarks found',
                                style: TextStyle(
                                  fontSize: 16.5,
                                  fontWeight: FontWeight.w700,
                                  color: dark
                                      ? AppColors.textWhite
                                      : AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Save questions during practice to review them anytime here.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: dark
                                      ? AppColors.darkGrey
                                      : AppColors.textSecondary,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (_, index) =>
                          BookmarkContainer(qn: filtered[index]),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

// ── Inline search bar widget ─────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.focusNode,
    required this.dark,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool dark;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSizes.defaultSpace,
        AppSizes.spaceBtwItems,
        AppSizes.defaultSpace,
        AppSizes.spaceBtwItems,
      ),
      child: TextFormField(
        controller: controller,
        focusNode: focusNode,
        onTapOutside: (_) => FocusScope.of(context).unfocus(),
        onChanged: onChanged,
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search, size: 20),
          suffixIcon: ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (_, value, __) => value.text.isEmpty
                ? const SizedBox.shrink()
                : IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: onClear,
                  ),
          ),
          border: _border(Colors.grey),
          enabledBorder: _border(
            dark ? Colors.grey.shade700 : Colors.grey.shade400,
          ),
          focusedBorder: _border(AppColors.primary),
          hintText: 'Search bookmarks…',
          hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
        ),
      ),
    );
  }

  OutlineInputBorder _border(Color color) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: color, width: 1.2),
  );
}
