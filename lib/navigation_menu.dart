import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matricmate/features/exam/screens/bookmark/bookmark.dart';
import 'package:matricmate/features/exam/screens/subject/subjects.dart';
import 'package:matricmate/features/exam/screens/result/result_review.dart';
import 'package:matricmate/features/personalization/profile.dart';

class NavigationMenu extends StatelessWidget {
  const NavigationMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(NavigationController());

    return Scaffold(
      bottomNavigationBar: Obx(
        () => NavigationBar(
          height: 60,
          elevation: 0,
          selectedIndex: controller.selectedIdx.value,
          onDestinationSelected: (index) =>
              controller.selectedIdx.value = index,
          destinations: [
            NavigationDestination(label: "Questions", icon: Icon(Icons.home)),
            NavigationDestination(
              label: "Bookmarks",
              icon: Icon(Icons.bookmark),
            ),
            NavigationDestination(label: "Profile", icon: Icon(Icons.person)),
          ],
        ),
      ),
      body: Obx(() => controller.screens[controller.selectedIdx.value]),
    );
  }
}

class NavigationController extends GetxController {
  final Rx<int> selectedIdx = 0.obs;

  final screens = [SubjectsScreen(), BookmarkScreen(), ProfileScreen()];
}
