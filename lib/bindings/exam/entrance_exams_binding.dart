import 'package:get/get.dart';
import 'package:matricmate/features/exam/controllers/entrance_exams_controller.dart';
import 'package:matricmate/features/exam/controllers/exam_selection_controller.dart';

class EntranceExamsBinding extends Bindings {
  @override
  void dependencies() {
    // ExamSelectionController owns the TabController for entrance/model tabs
    Get.lazyPut<ExamSelectionController>(
      () => ExamSelectionController(),
      fenix: true,
    );
    // ExamsController loads tests for the selected subject
    Get.lazyPut<ExamsController>(() => ExamsController(), fenix: true);
  }
}
