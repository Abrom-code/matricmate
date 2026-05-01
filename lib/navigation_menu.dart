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
              label: "Test",
            ),
            NavigationDestination(
              icon: Icon(Iconsax.book_1_copy),
              label: "Exam",
            ),
            NavigationDestination(
              icon: Icon(Iconsax.archive_tick_copy),
              label: "Bookmark",
            ),
            NavigationDestination(
              icon: Icon(Iconsax.user_copy),
              label: "Profile",
            ),
          ],
        ),
      ),

      body: Navigator(
        key: Get.nestedKey(NavigationController.navigatorId),
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
  final Rx<int> selectedIdx = 0.obs;
  static const int navigatorId = 1;

  final List<String> routes = [
    Routes.home,
    Routes.entrance,
    Routes.bookmark,
    Routes.userProfile,
  ];

  // Add this specific method
  void backToHome() {
    selectedIdx.value = 0;

    final nestedNavigator = Get.nestedKey(navigatorId)!.currentState;

    if (nestedNavigator != null) {
      nestedNavigator.popUntil((route) => route.isFirst);
    }
  }

  void changePage(int index) {
    if (selectedIdx.value == index) return;
    selectedIdx.value = index;
    Get.offNamed(routes[index], id: navigatorId);
  }
}
