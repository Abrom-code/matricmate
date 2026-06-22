import 'package:get/get.dart';
import 'package:matricmate/features/exam/controllers/chapter_controller.dart';
import 'package:matricmate/features/exam/controllers/grade_selection_controller.dart';

class ChapterBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ChapterController>(() => ChapterController());
    Get.lazyPut<GradeSelectionController>(() => GradeSelectionController());
  }
}
