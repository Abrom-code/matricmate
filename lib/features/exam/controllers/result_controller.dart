import 'package:get/get.dart';
import 'package:matricmate/features/exam/models/result_model.dart';

class ResultController extends GetxController {
  static ResultController get instance => Get.find();

  late ResultModel result;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args == null || args is! Map || args['result'] is! ResultModel) {
      Get.back();
      return;
    }
    result = args['result'] as ResultModel;
  }
}
