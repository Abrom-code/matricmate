import 'package:flutter/material.dart';
import 'package:get/get.dart';

class GradeSelectionController extends GetxController
    with GetSingleTickerProviderStateMixin {
  static GradeSelectionController get instance => Get.find();

  late TabController tabController;

  final List<Tab> tabs = const [
    Tab(text: "Grade 9"),
    Tab(text: "Grade 10"),
    Tab(text: "Grade 11"),
    Tab(text: "Grade 12"),
    Tab(text: "All"),
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
