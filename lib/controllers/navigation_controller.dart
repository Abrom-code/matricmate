import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matricmate/data/services/fcm_service.dart';
import 'package:matricmate/features/exam/controllers/bookmark_controller.dart';
import 'package:matricmate/features/exam/screens/bookmark/bookmark.dart';
import 'package:matricmate/features/exam/screens/entrance/entrance.dart';
import 'package:matricmate/features/exam/screens/subject/subjects.dart';
import 'package:matricmate/features/personalization/screens/analytics/analytics_screen.dart';
import 'package:matricmate/features/personalization/screens/profile/profile.dart';

class NavigationController extends GetxController with WidgetsBindingObserver {
  static NavigationController get instance => Get.find();

  final Rx<int> selectedIdx = 0.obs;

  late final PageController pageController;

  /// Screens are instantiated once and kept alive via AutomaticKeepAlive.
  late final List<Widget> pages;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    pageController = PageController(initialPage: 0);

    // Ensure notification permissions are requested on startup / main screen visit
    unawaited(FcmService.instance.requestPermissionIfNeeded());

    // Ensure BookmarkController is registered before BookmarkScreen builds.
    if (!Get.isRegistered<BookmarkController>()) {
      Get.lazyPut<BookmarkController>(() => BookmarkController(), fenix: true);
    }

    pages = [
      _KeepAlivePage(child: SubjectsScreen()),
      const _KeepAlivePage(child: EntranceScreen()),
      _KeepAlivePage(child: BookmarkScreen()),
      const _KeepAlivePage(child: AnalyticsScreen()),
      const _KeepAlivePage(child: ProfileScreen()),
    ];
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    pageController.dispose();
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(FcmService.instance.requestPermissionIfNeeded());
    }
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
    if (index == 0) {
      unawaited(FcmService.instance.requestPermissionIfNeeded());
    }
  }

  /// Called when the user swipes — syncs the nav bar indicator.
  void onPageChanged(int index) {
    selectedIdx.value = index;
    if (index == 0) {
      unawaited(FcmService.instance.requestPermissionIfNeeded());
    }
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
