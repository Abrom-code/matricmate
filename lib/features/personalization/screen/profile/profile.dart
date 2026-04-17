import 'package:flutter/material.dart';
import 'package:matricmate/common/widgets/appbar/appbar.dart';
import 'package:matricmate/common/widgets/dialogs/confirm_dialog_box.dart';
import 'package:matricmate/data/repositories/authentication/authentication_repository.dart';
import 'package:matricmate/features/personalization/screen/profile/widgets/account_settings.dart';
import 'package:matricmate/features/personalization/screen/profile/widgets/analytics_container.dart';
import 'package:matricmate/features/personalization/screen/profile/widgets/profile_section.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/constants/sizes.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = AppHelperFuntions.isDark(context);
    return Scaffold(
      appBar: Appbar(
        title: Text("Profile", style: TextStyle(color: AppColors.white)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(AppSizes.defaultSpace),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: ProfileSection()),
              const SizedBox(height: AppSizes.spaceBtwSections),

              AnalyticsContainer(),
              const SizedBox(height: AppSizes.spaceBtwSections),

              Text(
                "ACCOUNT SETTINGS",
                style: Theme.of(context).textTheme.titleMedium!.copyWith(
                  color: dark ? AppColors.grey : AppColors.darkerGrey,
                ),
              ),
              SizedBox(height: AppSizes.spaceBtwItems),

              AccountSettings(),
              SizedBox(height: AppSizes.spaceBtwSections),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => AppDialogBoxes.showOkCancelDialog(
                    context: context,
                    onPressed: () => AuthenticationRepository.instance.logout(),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.red),
                  ),
                  child: Text('Log Out', style: TextStyle(color: Colors.red)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
