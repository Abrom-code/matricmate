import 'package:get/get.dart';
import 'package:matricmate/features/exam/controllers/entrance_exams_controller.dart';

class EntranceExamsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ExamsController>(() => ExamsController(), fenix: true);
  }
}
