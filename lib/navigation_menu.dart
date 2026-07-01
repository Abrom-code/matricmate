import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:matricmate/routes/app_routes.dart';
import 'package:matricmate/routes/routes.dart';

class NavigationMenu extends StatelessWidget {
  const NavigationMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<NavigationController>();

    return Scaffold(
      bottomNavigationBar: Obx(
        () => NavigationBar(
          height: 70,
          selectedIndex: controller.selectedIdx.value,
          onDestinationSelected: controller.changePage,
          destinations: const [
            NavigationDestination(
              icon: Icon(Iconsax.message_question_copy),
              label: 'Test',
            ),
            NavigationDestination(
              icon: Icon(Iconsax.book_1_copy),
              label: 'Exam',
            ),
            NavigationDestination(
              icon: Icon(Iconsax.archive_tick_copy),
              label: 'Bookmark',
            ),
            NavigationDestination(
              icon: Icon(Iconsax.user_copy),
              label: 'Profile',
            ),
          ],
        ),
      ),

      body: Navigator(
        // Key is owned by the controller — created once, never recreated
        // on widget rebuilds, which prevents the duplicate GlobalKey error.
        key: controller.navigatorKey,
        initialRoute: Routes.home,
        onGenerateRoute: (settings) {
          final routePage = AppRoutes.pages.firstWhere(
            (page) => page.name == settings.name,
            orElse: () => AppRoutes.pages.first,
          );

          return GetPageRoute(
            routeName: routePage.name,
            page: routePage.page,
            binding: routePage.binding,
            settings: settings,
          );
        },
      ),
    );
  }
}

class NavigationController extends GetxController {
  static NavigationController get instance => Get.find();

  final Rx<int> selectedIdx = 0.obs;
  static const int navigatorId = 1;

  /// Single stable key for the nested Navigator.
  /// Owned by the controller so it survives widget rebuilds without
  /// being recreated — prevents the duplicate GlobalKey assertion.
  final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'bottom_nav');

  final List<String> routes = [
    Routes.home,
    Routes.entrance,
    Routes.bookmark,
    Routes.userProfile,
  ];

  void backToHome() {
    selectedIdx.value = 0;
    navigatorKey.currentState?.popUntil((route) => route.isFirst);
  }

  void changePage(int index) {
    if (selectedIdx.value == index) return;
    selectedIdx.value = index;
    navigatorKey.currentState?.pushNamedAndRemoveUntil(
      routes[index],
      (route) => false,
    );
  }
}
