import 'package:get/get.dart';
import 'package:matricmate/features/exam/controllers/result_controller.dart';

class ResultBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ResultController>(() => ResultController(), fenix: true);
  }
}
