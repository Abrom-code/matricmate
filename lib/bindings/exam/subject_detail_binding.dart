import 'package:get/get.dart';
import 'package:matricmate/features/exam/controllers/chapter_controller.dart';
import 'package:matricmate/features/exam/controllers/entrance_exams_controller.dart';
import 'package:matricmate/features/exam/controllers/exam_selection_controller.dart';
import 'package:matricmate/features/exam/controllers/grade_selection_controller.dart';

class SubjectDetailBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ChapterController>(() => ChapterController(), fenix: true);
    Get.lazyPut<GradeSelectionController>(
      () => GradeSelectionController(),
      fenix: true,
    );
    Get.lazyPut<ExamSelectionController>(
      () => ExamSelectionController(),
      fenix: true,
    );
    Get.lazyPut<EntranceExamsController>(
      () => EntranceExamsController(),
      fenix: true,
    );
  }
}
