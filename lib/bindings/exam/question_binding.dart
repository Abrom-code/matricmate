import 'package:get/get.dart';
import 'package:matricmate/features/exam/controllers/bookmark_controller.dart';
import 'package:matricmate/features/exam/controllers/question_controller.dart';

class QuestionBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<QuestionController>(() => QuestionController(), fenix: true);
    Get.lazyPut<BookmarkController>(() => BookmarkController(), fenix: true);
  }
}
