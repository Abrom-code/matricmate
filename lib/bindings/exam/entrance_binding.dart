import 'package:get/get.dart';
import 'package:matricmate/features/exam/controllers/exam_selection_controller.dart';

class EntranceBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ExamSelectionController>(
      () => ExamSelectionController(),
      fenix: true,
    );
  }
}
