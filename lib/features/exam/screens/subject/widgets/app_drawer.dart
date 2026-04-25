import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matricmate/common/widgets/appbar/status_title.dart';
import 'package:matricmate/features/exam/screens/premium/widgets/premium_bottom_sheet.dart';
import 'package:matricmate/features/personalization/controller/user_controller.dart';
import 'package:matricmate/navigation_menu.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';
import 'package:matricmate/utils/themes/theme_controller.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final userName = UserController.instance.user.value.firstName;
    final stream = UserController.instance.user.value.stream.toUpperCase();

    final dark = AppHelperFuntions.isDark(context);
    return Drawer(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(left: 16, top: 60, bottom: 15),
            decoration: const BoxDecoration(color: AppColors.primary),
            child: SafeArea(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.darkerGrey,
                    child: Icon(Icons.person, color: Colors.white, size: 30),
                  ),
                  const SizedBox(width: 20),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppbarStatusTitle(title: userName),

                      Text(
                        "Stream: $stream",
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  Spacer(),
                  IconButton(
                    onPressed: () {
                      ThemeController.instance.toogleTheme(!dark);
                      Get.back();
                    },
                    icon: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Icon(
                        dark ? Icons.sunny : Icons.dark_mode,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // MENU ITEMS
          Expanded(
            child: Obx(() {
              final isPending = UserController.instance.user.value.isPending;
              final isInactive = UserController.instance.user.value.isInactive;
              return ListView(
                padding: EdgeInsets.zero,
                children: [
                  ListTile(
                    leading: const Icon(Icons.home_outlined),
                    title: Text("Home"),
                    onTap: () => Get.back(),
                  ),
                  ListTile(
                    leading: const Icon(Icons.bookmark_outline),
                    title: const Text("Bookmarks"),
                    onTap: () =>
                        Get.offAll(() => NavigationMenu(initialIndex: 1)),
                  ),
                  ListTile(
                    leading: const Icon(Icons.person_outline),
                    title: const Text("Profile"),
                    onTap: () =>
                        Get.offAll(() => NavigationMenu(initialIndex: 2)),
                  ),
                  if (isInactive)
                    ListTile(
                      leading: const Icon(
                        Icons.workspace_premium,
                        color: Colors.amber,
                      ),
                      title: const Text("Subscribe Premium"),
                      onTap: () {
                        Get.back();
                        Get.bottomSheet(
                          const PremiumBottomSheet(),
                          isScrollControlled: true,
                        );
                      },
                    ),

                  if (isPending)
                    ListTile(
                      leading: const Icon(Icons.refresh),
                      title: const Text("Refresh Payment"),
                      onTap: () async {
                        Get.back();
                        await UserController.instance.checkPaymentStatus();
                      },
                    ),
                  Divider(),

                  ListTile(
                    leading: const Icon(
                      Icons.telegram,
                      color: Colors.lightBlue,

                      size: 30,
                    ),
                    title: const Text("Telegram"),
                    onTap: () {},
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.smart_display,
                      color: Colors.red,
                      size: 30,
                    ),
                    title: const Text("YouTube"),
                    onTap: () {},
                  ),
                  ListTile(
                    leading: const Icon(Icons.tiktok),
                    title: const Text("TikTok"),
                    onTap: () {},
                  ),
                ],
              );
            }),
          ),

          const Divider(height: 1),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Text("Version 1.0.0"),
          ),
        ],
      ),
    );
  }
}
