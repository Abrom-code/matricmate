import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_instance/src/bindings_interface.dart';
import 'package:get/get_instance/src/extension_instance.dart';
import 'package:matricmate/features/exam/controllers/chapter_controller.dart';
import 'package:matricmate/features/exam/controllers/grade_selection_controller.dart';
import 'package:matricmate/features/exam/controllers/question_controller.dart';
import 'package:matricmate/features/exam/controllers/test_controller.dart';

class ChapterBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => ChapterController());
    Get.lazyPut(() => GradeSelectionController());
    Get.put(TestController(), permanent: true);
    Get.put(QuestionController(), permanent: true);
  }
}
