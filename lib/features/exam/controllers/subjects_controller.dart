import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matricmate/data/repositories/exam/subject_repository.dart';
import 'package:matricmate/features/exam/controllers/syncing_controller.dart';
import 'package:matricmate/features/exam/models/subject_model.dart';
import 'package:matricmate/features/personalization/controller/user_controller.dart';
import 'package:matricmate/utils/helpers/toast_helper.dart';
import 'package:matricmate/utils/network_manager/network_manager.dart';

class SubjectsController extends GetxController {
  static SubjectsController get instance => Get.find();

  final SubjectRepository _repo = SubjectRepository();

  final RxBool isLoading = false.obs;
  final RxMap<String, bool> downloadingMap = <String, bool>{}.obs;

  final RxList<SubjectMoModel> subjects = <SubjectMoModel>[].obs;

  final RxString selectedStream = UserController.instance.user.value.stream.obs;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void onInit() {
    loadLocalSubjects();

    ever(UserController.instance.user, (user) {
      selectedStream.value = user.stream;
    });

    super.onInit();
  }

  /// LOCAL ONLY (startup)
  Future<void> loadLocalSubjects() async {
    try {
      isLoading.value = true;

      final dbSubjects = await _repo.getLocalSubjects();

      subjects.assignAll(
        dbSubjects.map((e) => SubjectMoModel.fromMap(e)).toList(),
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> syncAll() async {
    await SyncingController.instance.syncAll();
    ToastHelper.success("Success", "All subjects synced successfully!");
  }

  Future<void> syncSubjects() async {
    try {
      final isConnected = await NetworkManager.instance.hasRealInternet();
      if (!isConnected) return;

      // 1. Fetch from Supabase
      final response = await _repo.getSupabaseSubjects();
      final remoteData = (response as List)
          .map((e) => SubjectMoModel.fromJson(e))
          .toList();

      for (final subject in remoteData) {
        await _repo.addSubject(subject);
      }

      await loadLocalSubjects();
    } catch (e) {
      ToastHelper.error("Sync failed", e.toString());
    }
  }

  /// DOWNLOAD SUBJECT
  Future<void> downloadSubject(String subject, int subjectId) async {
    try {
      final isConnected = await NetworkManager.instance.hasRealInternet();
      if (!isConnected) {
        ToastHelper.warning("No Internet!", "Connect to internet first");
        return;
      }

      downloadingMap[subject] = true;

      await _repo.downloadSubject(subjectId);
      await _repo.updateIsDownloaded(subject);

      await loadLocalSubjects();
    } finally {
      downloadingMap[subject] = false;
    }
  }

  List<SubjectMoModel> get filteredSubjects {
    final isNatural = selectedStream.value == "natural";

    return subjects.where((subject) {
      return subject.isCommon || subject.isNatural == (isNatural ? 1 : 0);
    }).toList();
  }
}
