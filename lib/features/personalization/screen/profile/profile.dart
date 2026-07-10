import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matricmate/common/widgets/appbar/modern_appbar.dart';
import 'package:matricmate/common/widgets/dialogs/confirm_dialog_box.dart';
import 'package:matricmate/features/personalization/controller/profile_controller.dart';
import 'package:matricmate/features/personalization/controller/user_controller.dart';
import 'package:matricmate/features/personalization/screen/profile/widgets/account_settings.dart';
import 'package:matricmate/features/personalization/screen/profile/widgets/connect_support_section.dart';
import 'package:matricmate/features/personalization/screen/profile/widgets/profile_section.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/constants/sizes.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    Get.put(ProfileController());
  }

  @override
  void dispose() {
    Get.delete<ProfileController>(force: true);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userController = Get.find<UserController>();
    final dark = AppHelperFunctions.isDark(context);

    return Scaffold(
      appBar: ModernAppbarWithBuilder(
        title: 'My Profile',
        subtitleBuilder: (_) => Obx(() {
          final fullName = UserController.instance.user.value.fullName.trim();
          return Text(
            fullName,
            style: const TextStyle(color: AppColors.darkGrey, fontSize: 12),
          );
        }),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.defaultSpace),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile card — has its own internal Obx
              const ProfileSection(),
              const SizedBox(height: AppSizes.spaceBtwSections),

              // Account settings
              Text(
                'ACCOUNT SETTINGS',
                style: Theme.of(context).textTheme.titleMedium!.copyWith(
                  color: dark ? AppColors.grey : AppColors.darkerGrey,
                ),
              ),
              const SizedBox(height: AppSizes.spaceBtwItems),
              const AccountSettings(),
              const SizedBox(height: AppSizes.spaceBtwSections),

              // Connect & support
              Text(
                'CONNECT & SUPPORT',
                style: Theme.of(context).textTheme.titleMedium!.copyWith(
                  color: dark ? AppColors.grey : AppColors.darkerGrey,
                ),
              ),
              const SizedBox(height: AppSizes.spaceBtwItems),
              const ConnectSupportSection(),
              const SizedBox(height: AppSizes.spaceBtwSections),

              // Log out
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => AppDialogBoxes.showOkCancelDialog(
                    context: context,
                    onPressed: () {
                      Get.back();
                      userController.logOut();
                    },
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                  ),
                  child: const Text(
                    'Log Out',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ),

              const SizedBox(height: AppSizes.spaceBtwSections * 2),
            ],
          ),
        ),
      ),
    );
  }
}
