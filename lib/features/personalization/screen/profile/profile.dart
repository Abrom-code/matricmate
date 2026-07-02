import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matricmate/common/widgets/appbar/appbar.dart';
import 'package:matricmate/common/widgets/dialogs/confirm_dialog_box.dart';
import 'package:matricmate/common/widgets/loaders/circular_loading.dart';
import 'package:matricmate/features/exam/screens/subject/widgets/app_drawer.dart';
import 'package:matricmate/features/personalization/controller/profile_controller.dart';
import 'package:matricmate/features/personalization/controller/user_controller.dart';
import 'package:matricmate/features/personalization/screen/profile/widgets/account_settings.dart';
import 'package:matricmate/features/personalization/screen/profile/widgets/profile_section.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/constants/sizes.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

class ProfileScreen extends StatelessWidget {
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final _userController = Get.find<UserController>();
    Get.put(ProfileController());
    final dark = AppHelperFunctions.isDark(context);
    return Scaffold(
      key: scaffoldKey,
      drawer: const AppDrawer(),
      appBar: Appbar(
        leadingIcon: Icons.menu,
        leadingOnPressed: () {
          scaffoldKey.currentState?.openDrawer();
        },
        title: const Text('Profile', style: TextStyle(color: AppColors.white)),
      ),
      body: Obx(() {
        if (UserController.instance.userFetching.value) {
          return const AppCircularLoading(title: 'Loading...');
        }
        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.defaultSpace),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ProfileSection(),
                const SizedBox(height: AppSizes.spaceBtwSections),

                Text(
                  'ACCOUNT SETTINGS',
                  style: Theme.of(context).textTheme.titleMedium!.copyWith(
                    color: dark ? AppColors.grey : AppColors.darkerGrey,
                  ),
                ),
                const SizedBox(height: AppSizes.spaceBtwItems),

                const AccountSettings(),
                const SizedBox(height: AppSizes.spaceBtwSections),

                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => AppDialogBoxes.showOkCancelDialog(
                      context: context,
                      onPressed: () {
                        Get.back();
                        _userController.logOut();
                      },
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                    ),
                    child: const Text('Log Out', style: TextStyle(color: Colors.red)),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}
