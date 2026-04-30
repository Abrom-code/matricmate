import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matricmate/common/widgets/appbar/status_title.dart';
import 'package:matricmate/common/widgets/tiles/list_tile.dart';
import 'package:matricmate/features/exam/screens/premium/widgets/premium_bottom_sheet.dart';
import 'package:matricmate/features/personalization/controller/user_controller.dart';
import 'package:matricmate/navigation_menu.dart';
import 'package:matricmate/utils/constants/app_strings.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/constants/sizes.dart';
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
                padding: EdgeInsets.only(bottom: AppSizes.defaultSpace / 2),
                children: [
                  AppListTile(
                    icon: Icon(Icons.home_outlined),
                    title: 'Home',
                    onTap: () {
                      Navigator.of(context).pop();
                      Get.find<NavigationController>().changePage(0);
                    },
                  ),
                  AppListTile(
                    icon: Icon(Icons.bookmark_outline),
                    title: 'Bookmarks',
                    onTap: () {
                      Navigator.of(context).pop();
                      Get.find<NavigationController>().changePage(1);
                    },
                  ),
                  AppListTile(
                    icon: Icon(Icons.person_outline),
                    title: 'Profile',
                    onTap: () {
                      Navigator.of(context).pop();
                      Get.find<NavigationController>().changePage(2);
                    },
                  ),

                  if (isInactive)
                    AppListTile(
                      icon: Icon(Icons.workspace_premium, color: Colors.amber),
                      title: 'Premium',
                      onTap: () {
                        Navigator.of(context).pop();
                        Get.bottomSheet(
                          const PremiumBottomSheet(),
                          isScrollControlled: true,
                        );
                      },
                    ),

                  if (isPending)
                    AppListTile(
                      icon: Icon(Icons.loop, color: Colors.amber),
                      title: 'Refresh Payment',
                      onTap: () async {
                        Navigator.of(context).pop();
                        await UserController.instance.checkPaymentStatus();
                      },
                    ),

                  const SizedBox(height: AppSizes.spaceBtwItems),
                  Container(
                    padding: EdgeInsets.only(left: AppSizes.defaultSpace),
                    child: Text(
                      "CONNECT & SUPPORT",
                      style: Theme.of(context).textTheme.titleLarge!.copyWith(
                        color: dark ? AppColors.darkGrey : AppColors.darkerGrey,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSizes.spaceBtwItems),

                  AppListTile(
                    icon: Icon(Icons.send_outlined),
                    title: 'Join Telegram',
                    onTap: () {
                      Navigator.of(context).pop();
                      AppHelperFuntions.openUrl(AppTextStrings.telegramChannel);
                    },
                  ),

                  AppListTile(
                    icon: Icon(Icons.star_outline),
                    title: 'Rate App',
                    onTap: () {
                      Navigator.of(context).pop();
                    },
                  ),
                  AppListTile(
                    icon: Icon(Icons.share),
                    title: 'Share with Friend',
                    onTap: () {
                      Navigator.of(context).pop();
                    },
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
