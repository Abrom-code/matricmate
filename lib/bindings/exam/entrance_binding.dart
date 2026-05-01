import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/src/bindings_interface.dart';
import 'package:get/get_instance/src/extension_instance.dart';
import 'package:matricmate/features/exam/controllers/entrance_exams_controller.dart';

class EntranceBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<EntranceExamsController>(() => EntranceExamsController());
  }
}
