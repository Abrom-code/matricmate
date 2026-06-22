import 'package:get/get.dart';
import 'package:matricmate/data/repositories/exam/subject_repository.dart';
import 'package:matricmate/features/exam/controllers/syncing_controller.dart';
import 'package:matricmate/features/exam/models/subject_model.dart';
import 'package:matricmate/features/personalization/controller/user_controller.dart';
import 'package:matricmate/utils/exceptions/exeption_handler.dart';
import 'package:matricmate/utils/helpers/toast_helper.dart';
import 'package:matricmate/utils/network_manager/network_manager.dart';

class SubjectsController extends GetxController {
  static SubjectsController get instance => Get.find();

  final SubjectRepository _repo = SubjectRepository();

  final RxBool isLoading = false.obs;
  final RxMap<String, bool> downloadingMap = <String, bool>{}.obs;

  final RxList<SubjectModel> subjects = <SubjectModel>[].obs;
  final RxMap<int, int> entranceTestNumbers = <int, int>{}.obs;
  final RxMap<int, int> modelTestNumbers = <int, int>{}.obs;

  final RxString selectedStream = UserController.instance.user.value.stream.obs;

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
        dbSubjects.map((e) => SubjectModel.fromMap(e)).toList(),
      );
      await loadTestNumbers(subjects);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> syncAll() async {
    try {
      final finished = await SyncingController.instance.syncAll();
      if (finished) {
        ToastHelper.success('All subjects synced successfully!');
      }
    } catch (e) {
      AppExceptionHandler.handleResponse(e);
    }
  }

  Future<void> syncSubjects() async {
    try {
      final isConnected = await NetworkManager.instance.hasRealInternet();
      if (!isConnected) return;

      // 1. Fetch from Supabase
      final response = await _repo.getSupabaseSubjects();
      final remoteData = (response as List)
          .map((e) => SubjectModel.fromJson(e))
          .toList();

      for (final subject in remoteData) {
        await _repo.addSubject(subject);
      }

      await loadLocalSubjects();
    } catch (e) {
      AppExceptionHandler.handleResponse(e);
    }
  }

  /// DOWNLOAD SUBJECT
  Future<void> downloadSubject(String subject, int subjectId) async {
    try {
      final isConnected = await NetworkManager.instance.hasRealInternet();
      if (!isConnected) {
        ToastHelper.warning('No Internet!');
        return;
      }

      downloadingMap[subject] = true;

      await _repo.downloadSubject(subjectId);
      await _repo.updateIsDownloaded(subject);

      await loadLocalSubjects();
      ToastHelper.success('Subject downloaded successfully');
    } catch (e) {
      AppExceptionHandler.handleResponse(e);
    } finally {
      downloadingMap[subject] = false;
    }
  }

  Future<void> loadTestNumbers(List<SubjectModel> subjects) async {
    try {
      await Future.wait(
        subjects.map((s) async {
          final entranceTests = await _repo.testNumbers(s.id, 'entrance');
          final modelTests = await _repo.testNumbers(s.id, 'model');

          entranceTestNumbers[s.id] = entranceTests;
          modelTestNumbers[s.id] = modelTests;
        }),
      );
    } catch (e) {
      AppExceptionHandler.handleResponse(e);
    }
  }

  List<SubjectModel> get filteredSubjects {
    final isNatural = selectedStream.value == 'natural';

    return subjects.where((subject) {
      return subject.isCommon || subject.isNatural == isNatural;
    }).toList();
  }
}
