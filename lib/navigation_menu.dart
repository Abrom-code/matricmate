import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:matricmate/features/exam/controllers/bookmark_controller.dart';
import 'package:matricmate/features/exam/screens/bookmark/bookmark.dart';
import 'package:matricmate/features/exam/screens/entrance/entrance.dart';
import 'package:matricmate/features/exam/screens/subject/subjects.dart';
import 'package:matricmate/features/personalization/screens/analytics/analytics_screen.dart';
import 'package:matricmate/features/personalization/screens/profile/profile.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

class NavigationMenu extends StatelessWidget {
  const NavigationMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<NavigationController>();

    return Scaffold(
      extendBody: true,
      bottomNavigationBar: Obx(
        () => _FloatingNavBar(
          selectedIndex: controller.selectedIdx.value,
          onTap: controller.changePage,
        ),
      ),
      body: PageView(
        controller: controller.pageController,
        physics: const ClampingScrollPhysics(), // no bounce — cleaner feel
        onPageChanged: controller.onPageChanged,
        children: controller.pages,
      ),
    );
  }
}

// ── Floating pill nav bar ────────────────────────────────────────────────────

class _FloatingNavBar extends StatelessWidget {
  const _FloatingNavBar({required this.selectedIndex, required this.onTap});

  final int selectedIndex;
  final void Function(int) onTap;

  static const _items = [
    _NavItem(icon: Iconsax.message_question_copy, label: 'Test'),
    _NavItem(icon: Iconsax.book_1_copy, label: 'Exam'),
    _NavItem(icon: Iconsax.archive_tick_copy, label: 'Bookmark'),
    _NavItem(icon: Iconsax.chart_copy, label: 'Analytics'),
    _NavItem(icon: Iconsax.user_copy, label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    final dark = AppHelperFunctions.isDark(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    final pillWidth = screenWidth > 480 ? 420.0 : screenWidth - 32.0;

    return Padding(
      padding: EdgeInsets.only(
        left: (screenWidth - pillWidth) / 2,
        right: (screenWidth - pillWidth) / 2,
        bottom: bottomInset + 10,
        top: 8,
      ),
      child: Container(
        height: 60,
        width: pillWidth,
        decoration: BoxDecoration(
          color: dark ? const Color(0xFF1E1E1E) : AppColors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: dark ? 0.40 : 0.12),
              blurRadius: 20,
              spreadRadius: -4,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(_items.length, (i) {
            final selected = i == selectedIndex;
            return _NavButton(
              item: _items[i],
              selected: selected,
              dark: dark,
              onTap: () {
                HapticFeedback.lightImpact();
                onTap(i);
              },
            );
          }),
        ),
      ),
    );
  }
}

// ── Single nav button ────────────────────────────────────────────────────────

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.item,
    required this.selected,
    required this.dark,
    required this.onTap,
  });

  final _NavItem item;
  final bool selected;
  final bool dark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(
          horizontal: selected ? 14 : 10,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              item.icon,
              size: 20,
              color: selected
                  ? AppColors.primary
                  : (dark ? Colors.white54 : AppColors.darkGrey),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              child: selected
                  ? Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: Text(
                        item.label,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Data class ───────────────────────────────────────────────────────────────

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}

// ── Controller ───────────────────────────────────────────────────────────────

class NavigationController extends GetxController {
  static NavigationController get instance => Get.find();

  final Rx<int> selectedIdx = 0.obs;

  late final PageController pageController;

  /// Screens are instantiated once and kept alive via AutomaticKeepAlive.
  late final List<Widget> pages;

  @override
  void onInit() {
    super.onInit();
    pageController = PageController(initialPage: 0);

    // Ensure BookmarkController is registered before BookmarkScreen builds.
    if (!Get.isRegistered<BookmarkController>()) {
      Get.lazyPut<BookmarkController>(() => BookmarkController(), fenix: true);
    }

    pages = [
      _KeepAlivePage(child: SubjectsScreen()),
      _KeepAlivePage(child: EntranceScreen()),
      _KeepAlivePage(child: BookmarkScreen()),
      const _KeepAlivePage(child: AnalyticsScreen()),
      const _KeepAlivePage(child: ProfileScreen()),
    ];
  }

  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }

  /// Called by the nav bar tap — animates the PageView.
  void changePage(int index) {
    if (selectedIdx.value == index) return;
    selectedIdx.value = index;
    pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  /// Called when the user swipes — syncs the nav bar indicator.
  void onPageChanged(int index) {
    selectedIdx.value = index;
  }
}

// ── Keep-alive wrapper ────────────────────────────────────────────────────────
// Prevents PageView from disposing screens when swiping away from them.

class _KeepAlivePage extends StatefulWidget {
  const _KeepAlivePage({required this.child});
  final Widget child;

  @override
  State<_KeepAlivePage> createState() => _KeepAlivePageState();
}

class _KeepAlivePageState extends State<_KeepAlivePage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
