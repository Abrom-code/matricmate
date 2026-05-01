import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ExamSelectionController extends GetxController
    with GetSingleTickerProviderStateMixin {
  static ExamSelectionController get instance => Get.find();

  late TabController tabController;

  final List<Map<String, dynamic>> tabs = const [
    {"label": "Entrance Exams", "type": 'entrance'},
    {"label": "Model Exams", "type": 'model'},
  ];

  @override
  void onInit() {
    tabController = TabController(length: tabs.length, vsync: this);
    super.onInit();
  }

  @override
  void onClose() {
    tabController.dispose();
    super.onClose();
  }
}
