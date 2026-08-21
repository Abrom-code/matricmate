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
                color: dark ? AppColors.darkCard : AppColors.white,
                child: TabBar(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.defaultSpace / 2,
                  ),
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  tabs: tabs.map((t) => Tab(text: t)).toList(),
                ),
              ),

              // ── Tab content ─────────────────────────────────────────
              Expanded(
                child: TabBarView(
                  children: tabs.map((subject) {
                    final filtered = ctrl.getBySubject(subject);
                    if (filtered.isEmpty) {
                      return const Center(child: Text('No bookmark found'));
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.all(AppSizes.defaultSpace / 2),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: AppSizes.spaceBtwItems),
                      itemBuilder: (_, index) =>
                          BookmarkContainer(qn: filtered[index]),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: AppSizes.spaceBtwSections * 2),
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
