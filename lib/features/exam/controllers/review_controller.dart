import 'package:get/get.dart';
import 'package:matricmate/features/exam/models/question_model.dart';
import 'package:matricmate/features/exam/models/result_model.dart';

class ReviewController extends GetxController {
  static ReviewController get instance => Get.find();

  final RxMap<int, bool> isExpanded = <int, bool>{}.obs;
  final RxString languageSelected = "EN".obs;
  late ResultModel result;

  @override
  void onInit() {
    final res = Get.arguments as ResultModel;
    result = res;
    initExpansion(res.testQuestions);
    super.onInit();
  }

  void initExpansion(List<QuestionModel> questions) {
    isExpanded.value = {for (var q in questions) q.id: false};
  }

  void toggle(int id) {
    isExpanded[id] = !(isExpanded[id] ?? false);
  }
}
