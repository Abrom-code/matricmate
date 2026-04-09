import 'package:get/get_instance/get_instance.dart';
import 'package:get/route_manager.dart';
import 'package:matricmate/data/database/database_service.dart';
import 'package:matricmate/utils/network_manager/network_manager.dart';

class GeneralBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(NetworkManager());
    Get.put(DatabaseService());
  }
}
