import 'package:flutter/material.dart';
import 'package:get/get.dart';
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
          height: 60,
          selectedIndex: controller.selectedIdx.value,
          onDestinationSelected: controller.changePage,
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home), label: "Questions"),
            NavigationDestination(
              icon: Icon(Icons.bookmark),
              label: "Bookmarks",
            ),
            NavigationDestination(icon: Icon(Icons.person), label: "Profile"),
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
    Routes.bookmark,
    Routes.userProfile,
  ];

  void changePage(int index) {
    if (selectedIdx.value == index) return;

    selectedIdx.value = index;

    Get.offNamed(routes[index], id: navigatorId);
  }
}
