import 'package:get/get.dart';
import 'package:matricmate/controllers/navigation_controller.dart';
import 'package:matricmate/data/database/database_service.dart';
import 'package:matricmate/data/repositories/user/user_repository.dart';
import 'package:matricmate/features/authentication/controllers/authentication_controller.dart';
import 'package:matricmate/features/exam/controllers/subjects_controller.dart';
import 'package:matricmate/features/exam/controllers/syncing_controller.dart';
import 'package:matricmate/features/notifications/controllers/notifications_controller.dart';
import 'package:matricmate/features/personalization/controllers/user_controller.dart';
import 'package:matricmate/utils/network_manager/network_manager.dart';

class GeneralBinding extends Bindings {
  @override
  void dependencies() {
    // Core services (permanent — never disposed)──
    Get.put(NetworkManager(), permanent: true);
    Get.put(DatabaseService(), permanent: true);
    Get.put(NavigationController(), permanent: true);
    Get.put(SyncingController(), permanent: true);
    Get.put(UserRepository(), permanent: true);
    Get.put(AuthenticationController(), permanent: true);
    Get.put(UserController(), permanent: true);
    Get.put(SubjectsController(), permanent: true);
    // Permanent so bell badge is reactive from first screen
    Get.put(NotificationsController(), permanent: true);
  }
}
