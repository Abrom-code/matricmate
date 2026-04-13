import 'package:get/get.dart';
import 'package:matricmate/features/exam/controllers/question_controller.dart';
import 'package:matricmate/features/exam/models/question_model.dart';

class ReviewController extends GetxController {
  static ReviewController get instance => Get.find();

  final RxMap<int, bool> isExpanded = <int, bool>{}.obs;
  final qnController = Get.find<QuestionController>();
  @override
  void onInit() {
    initExpansion(qnController.testQuestions);
    super.onInit();
  }

  void initExpansion(List<QuestionModel> questions) {
    isExpanded.value = {for (var q in questions) q.id: false};
  }

  void toggle(int id) {
    isExpanded[id] = !(isExpanded[id] ?? false);
  }
}
