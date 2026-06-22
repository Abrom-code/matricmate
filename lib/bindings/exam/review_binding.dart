import 'package:get/get.dart';
import 'package:matricmate/features/exam/controllers/review_controller.dart';

class ReviewBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ReviewController>(() => ReviewController());
  }
}
