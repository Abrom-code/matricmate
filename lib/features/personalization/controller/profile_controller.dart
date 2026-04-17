import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:matricmate/data/database/database_service.dart';

class ProfileController extends GetxController {
  static ProfileController get instance => Get.find();
  final DatabaseService _databaseService = DatabaseService.instance;
  final completedTest = 0.obs;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      loadCompletedTests();
    });
  }

  Future<void> loadCompletedTests() async {
    completedTest.value = await _databaseService.getCompletedTests();
  }
}
