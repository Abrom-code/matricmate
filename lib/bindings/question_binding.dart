import 'package:get/get_instance/get_instance.dart';
import 'package:get/state_manager.dart';
import 'package:matricmate/bindings/general_binding.dart';
import 'package:matricmate/features/exam/controllers/question_controller.dart';

class QuestionBinding extends GeneralBinding {
  @override
  void dependencies() {
    Get.lazyPut(() => QuestionController());
    super.dependencies();
  }
}
