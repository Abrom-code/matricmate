import 'package:get/get.dart';
import 'package:matricmate/features/exam/controllers/bookmark_controller.dart';

class BookmarkBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<BookmarkController>(() => BookmarkController(), fenix: true);
  }
}
