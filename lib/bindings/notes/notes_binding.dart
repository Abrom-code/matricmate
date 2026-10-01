import 'package:get/get.dart';
import 'package:matricmate/features/exam/controllers/grade_selection_controller.dart';
import 'package:matricmate/features/notes/controllers/notes_controller.dart';

class NotesBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<NotesController>(() => NotesController(), fenix: true);
    Get.lazyPut<GradeSelectionController>(
      () => GradeSelectionController(),
      fenix: true,
    );
  }
}
