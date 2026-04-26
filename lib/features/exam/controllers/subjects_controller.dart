import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matricmate/data/repositories/exam/subject_repository.dart';
import 'package:matricmate/features/exam/models/subject_model.dart';
import 'package:matricmate/features/personalization/controller/user_controller.dart';
import 'package:matricmate/utils/exceptions/app_failure_model.dart';
import 'package:matricmate/utils/helpers/toast_helper.dart';
import 'package:matricmate/utils/network_manager/network_manager.dart';

class SubjectsController extends GetxController {
  static SubjectsController get instance => Get.find();

  final SubjectRepository _repo = SubjectRepository();

  final RxBool isLoading = false.obs;
  final RxBool isDownloading = false.obs;

  final RxString selectedStream = UserController.instance.user.value.stream.obs;

  final RxMap<String, bool> downloadingMap = <String, bool>{}.obs;

  final RxList<SubjectMoModel> subjects = <SubjectMoModel>[].obs;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void onInit() {
    loadSubjects();

    ever(UserController.instance.user, (user) {
      selectedStream.value = user.stream;
    });

    super.onInit();
  }

  /// LOAD SUBJECTS
  Future<void> loadSubjects() async {
    try {
      isLoading.value = true;

      final dbSubjects = await _repo.getLocalSubjects();

      if (dbSubjects.isNotEmpty) {
        subjects.assignAll(
          dbSubjects.map((e) => SubjectMoModel.fromMap(e)).toList(),
        );
        return;
      }

      final isConnectd = await NetworkManager.instance.hasRealInternet();
      if (!isConnectd) {
        ToastHelper.warning(
          "No Internet!",
          "Please turn on mobile data or connect to WIFI!",
        );
      }

      final response = await _repo.getSupabaseSubjects();

      final data = (response as List)
          .map((e) => SubjectMoModel.fromJson(e))
          .toList();

      subjects.assignAll(data);

      for (final subject in data) {
        await _repo.addSubject(subject);
      }
    } catch (e) {
      if (e is AppFailure) {
        ToastHelper.error(e.title, e.message);
      } else {
        ToastHelper.error("Unexpected Error", e.toString());
      }
    } finally {
      isLoading.value = false;
    }
  }

  /// DOWNLOAD SUBJECT (FIXED)
  Future<void> downloadSubject(String subject, int subjectId) async {
    try {
      final isConnectd = await NetworkManager.instance.hasRealInternet();
      if (!isConnectd) {
        ToastHelper.warning(
          "No Internet!",
          "Please turn on mobile data or connect to WIFI!",
        );
        return;
      }
      downloadingMap[subject] = true;

      await _repo.downloadSubject(subjectId);

      /// Mark as downloaded in DB
      await _repo.updateIsDownloaded(subject);

      ///  Refresh subjects
      await loadSubjects();
    } catch (e) {
      if (e is AppFailure) {
        ToastHelper.error(e.title, e.message);
      } else {
        ToastHelper.error("Unexpected Error", e.toString());
      }
    } finally {
      downloadingMap[subject] = false;
    }
  }

  List<SubjectMoModel> get filteredSubjects {
    final isNatural = selectedStream.value == "natural";

    return subjects.where((subject) {
      // ignore: unrelated_type_equality_checks
      return subject.isCommon || subject.isNatural == (isNatural ? 1 : 0);
    }).toList();
  }
}
