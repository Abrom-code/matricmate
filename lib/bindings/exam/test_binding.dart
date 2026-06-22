import 'package:get/get.dart';
import 'package:matricmate/features/exam/controllers/chapter_test_controller.dart';

class TestBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ChapterTestController>(() => ChapterTestController());
  }
}
