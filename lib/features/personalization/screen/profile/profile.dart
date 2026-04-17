import 'package:flutter/material.dart';
import 'package:matricmate/common/widgets/appbar/appbar.dart';
import 'package:matricmate/data/repositories/authentication/authentication_repository.dart';
import 'package:matricmate/features/personalization/screen/profile/widgets/analytics_container.dart';
import 'package:matricmate/features/personalization/screen/profile/widgets/profile_section.dart';
import 'package:matricmate/features/personalization/screen/profile/widgets/profile_tile.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/constants/sizes.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';
import 'package:matricmate/utils/themes/theme_controller.dart';

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

              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppSizes.md),
                  color: !dark ? AppColors.light : AppColors.black,
                ),
                child: Column(
                  children: [
                    ProfileTile(
                      icon: Icon(Icons.person),
                      title: "Edit Profile",
                      trailing: Icon(Icons.keyboard_arrow_right),

                      onTap: () {},
                    ),
                    ProfileTile(
                      icon: Icon(Icons.lock),
                      title: "Change Password",
                      trailing: Icon(Icons.keyboard_arrow_right),
                      onTap: () {},
                    ),
                    ProfileTile(
                      icon: Icon(Icons.help),
                      title: "Help & Support",
                      trailing: Icon(Icons.keyboard_arrow_right),
                      onTap: () {},
                    ),
                    ProfileTile(
                      icon: Icon(Icons.sunny),
                      title: "Change Theme",
                      trailing: Switch(
                        value: dark,
                        onChanged: (value) =>
                            ThemeController.instance.toogleTheme(value),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: AppSizes.spaceBtwSections),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => AuthenticationRepository.instance.logout(),
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
