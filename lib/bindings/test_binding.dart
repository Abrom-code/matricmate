import 'package:get/get_instance/get_instance.dart';
import 'package:get/route_manager.dart';
import 'package:matricmate/bindings/general_binding.dart';
import 'package:matricmate/features/exam/controllers/test_controller.dart';

class TestBinding extends GeneralBinding {
  @override
  void dependencies() {
    Get.lazyPut(() => TestController());
    super.dependencies();
  }
}
