import 'package:get/get.dart';
import 'package:matricmate/data/database/database_service.dart';
import 'package:matricmate/data/services/download_subject.dart';
import 'package:matricmate/features/exam/models/subject_model.dart';
import 'package:matricmate/features/personalization/controller/user_controller.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';
import 'package:matricmate/utils/helpers/toast_helper.dart';
import 'package:matricmate/utils/network_manager/network_manager.dart';
import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SubjectsController extends GetxController {
  static SubjectsController get instance => Get.find();

  final SupabaseClient supabase = Supabase.instance.client;
  final DatabaseService _dbService = DatabaseService.instance;

  final RxBool isLoading = false.obs;
  final RxBool isDownloading = false.obs;

  late RxString selectedStream;

  final RxMap<String, bool> downloadingMap = <String, bool>{}.obs;

  final RxList<SubjectMoModel> subjects = <SubjectMoModel>[].obs;

  @override
  void onInit() {
    loadSubjects();

    selectedStream = UserController.instance.user.value.stream.obs;

    ever(UserController.instance.user, (user) {
      selectedStream.value = user.stream;
    });

    super.onInit();
  }

  /// LOAD SUBJECTS
  Future<void> loadSubjects() async {
    try {
      isLoading.value = true;

      final dbSubjects = await _dbService.getSubjects();

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

      final response = await supabase.from("subjects").select();

      final data = (response as List)
          .map((e) => SubjectMoModel.fromJson(e))
          .toList();

      subjects.assignAll(data);

      final db = await _dbService.database;

      for (final subject in data) {
        await db.insert(
          'subjects',
          subject.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    } catch (e) {
      AppHelperFuntions.showAlert("Subject Error", e.toString());
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
      final service = SubjectDownloadService();
      await service.downloadSubject(subjectId);

      /// Mark as downloaded in DB
      final db = await _dbService.database;

      await db.update(
        'subjects',
        {'is_downloaded': 1},
        where: 'name = ?',
        whereArgs: [subject],
      );

      /// 4. Refresh subjects
      await loadSubjects();
    } catch (e) {
      AppHelperFuntions.showAlert("Subject Download Error", e.toString());
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
