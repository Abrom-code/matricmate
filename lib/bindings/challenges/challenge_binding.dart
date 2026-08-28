import 'package:get/get.dart';
import 'package:matricmate/features/challenges/controllers/challenge_archive_controller.dart';
import 'package:matricmate/features/challenges/controllers/challenge_home_controller.dart';

class ChallengeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ChallengeHomeController>(() => ChallengeHomeController());
    Get.lazyPut<ChallengeArchiveController>(() => ChallengeArchiveController());
  }
}
