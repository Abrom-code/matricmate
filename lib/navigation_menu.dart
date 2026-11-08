import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:matricmate/controllers/navigation_controller.dart';
import 'package:matricmate/features/tips_and_news/controllers/tips_and_news_controller.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

class NavigationMenu extends StatelessWidget {
  const NavigationMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<NavigationController>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.requestNotificationPermissionIfNeeded();
    });

    return Scaffold(
      extendBody: true,
      bottomNavigationBar: Obx(
        () {
          final tipsController = TipsAndNewsController.instance;
          return _FloatingNavBar(
            selectedIndex: controller.selectedIdx.value,
            hasOthersBadge: tipsController.hasUnread,
            onTap: controller.changePage,
          );
        },
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

// ── Floating pill nav bar (Telegram-style vertical layout) ────────────────────

class _FloatingNavBar extends StatelessWidget {
  const _FloatingNavBar({
    required this.selectedIndex,
    required this.onTap,
    this.hasOthersBadge = false,
  });

  final int selectedIndex;
  final void Function(int) onTap;
  final bool hasOthersBadge;

  static const _items = [
    _NavItem(icon: Iconsax.book_1_copy, label: 'Practice'),
    _NavItem(icon: Iconsax.cup_copy, label: 'Challenge'),
    _NavItem(icon: Iconsax.category_copy, label: 'Others'),
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
        height: 64,
        width: pillWidth,
        decoration: BoxDecoration(
          color: dark ? const Color(0xFF1E1E1E) : AppColors.white,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: dark ? 0.40 : 0.10),
              blurRadius: 20,
              spreadRadius: -4,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: List.generate(_items.length, (i) {
            final selected = i == selectedIndex;
            final isOthers = _items[i].label == 'Others';
            return Expanded(
              child: _NavButton(
                item: _items[i],
                selected: selected,
                showBadge: isOthers && hasOthersBadge,
                dark: dark,
                onTap: () {
                  HapticFeedback.lightImpact();
                  onTap(i);
                },
              ),
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
    this.showBadge = false,
  });

  final _NavItem item;
  final bool selected;
  final bool dark;
  final VoidCallback onTap;
  final bool showBadge;

  @override
  Widget build(BuildContext context) {
    final activeColor = AppColors.primary;
    final inactiveColor = dark ? Colors.white54 : AppColors.darkGrey;
    final color = selected ? activeColor : inactiveColor;
    final barBgColor = dark ? const Color(0xFF1E1E1E) : AppColors.white;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedScale(
                  scale: selected ? 1.08 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  child: Icon(
                    item.icon,
                    size: 22,
                    color: color,
                  ),
                ),
                if (showBadge)
                  Positioned(
                    top: -2,
                    right: -3,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: barBgColor,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: color,
                letterSpacing: -0.1,
              ),
              child: Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
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
