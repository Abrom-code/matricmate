import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/src/bindings_interface.dart';
import 'package:get/get_instance/src/extension_instance.dart';
import 'package:matricmate/features/exam/controllers/grade_test_controller.dart';

class GradeTestBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<GradeTestController>(() => GradeTestController());
  }
}
