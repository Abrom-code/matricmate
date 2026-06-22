import 'package:flutter/material.dart';
import 'package:get/get.dart';

class GradeSelectionController extends GetxController
    with GetSingleTickerProviderStateMixin {
  static GradeSelectionController get instance => Get.find();

  late TabController tabController;

  final List<Map<String, dynamic>> tabs = const [
    {'label': 'Grade 9', 'grade': 9},
    {'label': 'Grade 10', 'grade': 10},
    {'label': 'Grade 11', 'grade': 11},
    {'label': 'Grade 12', 'grade': 12},
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
