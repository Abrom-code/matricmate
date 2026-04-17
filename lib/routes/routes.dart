import 'package:get/get_navigation/src/routes/get_route.dart';
import 'package:matricmate/features/authentication/screens/login/login.dart';
import 'package:matricmate/features/authentication/screens/password_configration/forget_password.dart';
import 'package:matricmate/features/authentication/screens/signup/signup.dart';
import 'package:matricmate/features/authentication/screens/signup/verify_email.dart';
import 'package:matricmate/features/exam/screens/bookmark/bookmark.dart';
import 'package:matricmate/features/exam/screens/subject/subjects.dart';
import 'package:matricmate/features/personalization/screen/profile/profile.dart';
import 'package:matricmate/routes/app_routes.dart';

class AppRoutes {
  static final pages = [
    GetPage(name: Routes.home, page: () => const SubjectsScreen()),
    GetPage(name: Routes.bookmark, page: () => const BookmarkScreen()),
    GetPage(name: Routes.userProfile, page: () => const ProfileScreen()),
    GetPage(name: Routes.signup, page: () => const SignupScreen()),
    GetPage(name: Routes.verifyEmail, page: () => const VerifyEmailScreen()),
    GetPage(name: Routes.signIn, page: () => const LoginScreen()),
    GetPage(name: Routes.forgetPassword, page: () => const ForgetPassword()),
    // Add more GetPage entries as needed
  ];
}
