import 'package:get/get.dart';
import 'package:matricmate/features/exam/controllers/premium_controller.dart';

class PremiumBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PremiumController>(() => PremiumController(), fenix: true);
  }
}
