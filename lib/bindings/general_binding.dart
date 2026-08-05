import 'package:get/get.dart';
import 'package:matricmate/controllers/navigation_controller.dart';
import 'package:matricmate/data/database/database_service.dart';
import 'package:matricmate/data/repositories/authentication/authentication_repository.dart';
import 'package:matricmate/data/repositories/user/user_repository.dart';
import 'package:matricmate/features/authentication/controllers/authentication_controller.dart';
import 'package:matricmate/features/authentication/controllers/login/forgot_password_controller.dart';
import 'package:matricmate/features/authentication/controllers/login/login_controller.dart';
import 'package:matricmate/features/authentication/controllers/signup/signup_controller.dart';
import 'package:matricmate/features/exam/controllers/subjects_controller.dart';
import 'package:matricmate/features/exam/controllers/syncing_controller.dart';
import 'package:matricmate/features/notifications/controllers/notifications_controller.dart';
import 'package:matricmate/features/personalization/controllers/change_password_controller.dart';
import 'package:matricmate/features/personalization/controllers/user_controller.dart';
import 'package:matricmate/utils/network_manager/network_manager.dart';

class GeneralBinding extends Bindings {
  @override
  void dependencies() {
    // ── Core services (permanent — never disposed) ──────────────────
    Get.put(NetworkManager(), permanent: true);
    Get.put(DatabaseService(), permanent: true);
    Get.put(NavigationController(), permanent: true);
    Get.put(SyncingController(), permanent: true);
    Get.put(AuthenticationRepository(), permanent: true);
    Get.put(UserRepository(), permanent: true);
    Get.put(AuthenticationController(), permanent: true);
    Get.put(UserController(), permanent: true);
    Get.put(SubjectsController(), permanent: true);
    // Registered permanently so the bell badge in the appbar is reactive
    // from the first screen — not only after the notifications route is opened.
    Get.put(NotificationsController(), permanent: true);

    // ── Auth controllers (permanent — avoids TextEditingController
    //    disposed crash; these are lightweight and needed app-wide) ──
    Get.put(LoginController(), permanent: true);
    Get.put(SignupController(), permanent: true);
    Get.put(ForgotPasswordController(), permanent: true);
    Get.put(ChangePasswordController(), permanent: true);
    // Note: VerifyEmailController and ResetPasswordController use
    // Get.arguments in onInit so they stay as lazyPut in their bindings.
  }
}
