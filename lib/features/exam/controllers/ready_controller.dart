import 'package:get/get.dart';

class ReadyController extends GetxController {
  static ReadyController get instance => Get.find();
  final isExamMode = false.obs;

  void changeExamMode() {
    isExamMode.value = !isExamMode.value;
  }
}
