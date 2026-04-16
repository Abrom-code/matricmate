import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/src/bindings_interface.dart';
import 'package:get/get_instance/src/extension_instance.dart';
import 'package:matricmate/features/exam/controllers/subjects_controller.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(SubjectsController());
  }
}
