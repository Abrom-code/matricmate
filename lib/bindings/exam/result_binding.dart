import 'package:get/get.dart';
import 'package:matricmate/features/exam/screens/result/result.dart';

class ResultBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ResultController>(() => ResultController(), fenix: true);
  }
}
