import 'package:get/get_instance/get_instance.dart';
import 'package:get/route_manager.dart';
import 'package:matricmate/data/database/database_service.dart';
import 'package:matricmate/data/repositories/authentication/authentication_repository.dart';
import 'package:matricmate/data/repositories/user/user_repository.dart';
import 'package:matricmate/features/authentication/controllers/authentication_controller.dart';
import 'package:matricmate/features/exam/controllers/subjects_controller.dart';
import 'package:matricmate/features/exam/controllers/syncing_controller.dart';
import 'package:matricmate/features/personalization/controller/user_controller.dart';
import 'package:matricmate/navigation_menu.dart';
import 'package:matricmate/utils/network_manager/network_manager.dart';
import 'package:matricmate/utils/themes/theme_controller.dart';

class GeneralBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(NetworkManager(), permanent: true);
    Get.put(DatabaseService(), permanent: true);
    Get.put(ThemeController(), permanent: true);
    Get.put(NavigationController(), permanent: true);

    Get.put(SyncingController(), permanent: true);
    Get.put(AuthenticationRepository(), permanent: true);
    Get.put(UserRepository(), permanent: true);
    Get.put(AuthenticationController(), permanent: true);

    Get.put(UserController(), permanent: true);
    Get.put(SubjectsController(), permanent: true);
  }
}
