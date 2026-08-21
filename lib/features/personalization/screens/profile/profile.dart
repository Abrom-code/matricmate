import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matricmate/common/widgets/appbar/modern_appbar.dart';
import 'package:matricmate/common/widgets/dialogs/confirm_dialog_box.dart';
import 'package:matricmate/features/personalization/controllers/profile_controller.dart';
import 'package:matricmate/features/personalization/controllers/user_controller.dart';
import 'package:matricmate/features/personalization/screens/profile/widgets/account_settings.dart';
import 'package:matricmate/features/personalization/screens/profile/widgets/connect_support_section.dart';
import 'package:matricmate/features/personalization/screens/profile/widgets/profile_section.dart';
import 'package:matricmate/utils/constants/colors.dart';
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
      backgroundColor: dark ? AppColors.dark : const Color(0xFFF8FAFC),
      appBar: ModernAppbarWithBuilder(
        title: 'My Profile',
        subtitleBuilder: (_) => Obx(() {
          final fullName = UserController.instance.user.value.fullName.trim();
          return Text(
            fullName.isNotEmpty ? fullName : 'Student Profile',
            style: const TextStyle(
              color: Color(0xFFD1FAE5),
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
            ),
          );
        }),
      ),
      body: Obx(() {
        final checking = UserController.instance.isCheckingPayment.value;
        final isLandscape =
            MediaQuery.orientationOf(context) == Orientation.landscape;
        final content = SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              16,
              16,
              MediaQuery.paddingOf(context).bottom + 100,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile card — has its own internal Obx
                const ProfileSection(),
                const SizedBox(height: 20),

                // Account settings
                Text(
                  'ACCOUNT SETTINGS',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                    color: dark ? AppColors.darkGrey : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 10),
                const AccountSettings(),
                const SizedBox(height: 20),

                // Connect & support
                Text(
                  'CONNECT & SUPPORT',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                    color: dark ? AppColors.darkGrey : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 10),
                const ConnectSupportSection(),
                const SizedBox(height: 24),

                // Log out
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: () => AppDialogBoxes.showOkCancelDialog(
                      context: context,
                      title: 'Log Out',
                      subtitle: 'Are you sure you want to log out of MatricMate?',
                      onPressed: () {
                        Get.back();
                        userController.logOut();
                      },
                    ),
                    icon: const Icon(
                      Icons.logout_rounded,
                      size: 18,
                      color: Color(0xFFEF4444),
                    ),
                    label: const Text(
                      'Log Out',
                      style: TextStyle(
                        color: Color(0xFFEF4444),
                        fontWeight: FontWeight.w700,
                        fontSize: 14.5,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444)
                          .withValues(alpha: dark ? 0.12 : 0.04),
                      side: BorderSide(
                        color: const Color(0xFFEF4444)
                            .withValues(alpha: dark ? 0.3 : 0.25),
                        width: 1.2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
        return Stack(
          children: [
            isLandscape
                ? Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 560),
                      child: content,
                    ),
                  )
                : content,

            // Indeterminate progress bar
            if (checking)
              const Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: LinearProgressIndicator(
                  minHeight: 3,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
          ],
        );
      }),
    );
  }
}
