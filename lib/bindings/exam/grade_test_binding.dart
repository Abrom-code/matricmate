import 'package:get/get.dart';
import 'package:matricmate/features/exam/controllers/grade_test_controller.dart';

class GradeTestBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<GradeTestController>(() => GradeTestController());
  }
}
