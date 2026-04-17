import 'package:get/get_instance/get_instance.dart';
import 'package:get/route_manager.dart';
import 'package:matricmate/data/database/database_service.dart';
import 'package:matricmate/features/exam/controllers/bookmark_controller.dart';
import 'package:matricmate/features/exam/controllers/subjects_controller.dart';
import 'package:matricmate/features/personalization/controller/user_controller.dart';
import 'package:matricmate/utils/network_manager/network_manager.dart';
import 'package:matricmate/utils/themes/theme_controller.dart';

class GeneralBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(NetworkManager());
    Get.put(DatabaseService(), permanent: true);
    Get.put(SubjectsController(), permanent: true);
    Get.put(BookmarkController(), permanent: true);
    Get.put(UserController(), permanent: true);
    Get.put(ThemeController(), permanent: true);
  }
}
