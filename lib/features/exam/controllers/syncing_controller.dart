import 'package:get/get.dart';
import 'package:matricmate/data/repositories/exam/subject_repository.dart';
import 'package:matricmate/data/repositories/exam/sync_repository.dart';
import 'package:matricmate/features/personalization/controller/user_controller.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';
import 'package:matricmate/utils/helpers/toast_helper.dart';
import 'package:matricmate/utils/network_manager/network_manager.dart';
import 'package:matricmate/features/exam/controllers/subjects_controller.dart';
import 'package:matricmate/features/exam/models/chapter_model.dart';
import 'package:matricmate/features/exam/models/question_model.dart';
import 'package:matricmate/features/exam/models/subject_model.dart';
import 'package:matricmate/features/exam/models/test_model.dart';
import 'package:matricmate/features/exam/models/passage_model.dart';

class SyncingController extends GetxController {
  static SyncingController get instance => Get.find();

  final SubjectRepository _subjectRepo = SubjectRepository();
  final SyncRepository _syncRepository = SyncRepository();

  final refreshing = false.obs;

  Future<void> syncAll() async {
    try {
      final isConnected = await NetworkManager.instance.hasRealInternet();
      if (!isConnected) {
        ToastHelper.warning(
          "No Internet!",
          "Please turn on mobile data or connect to WIFI!",
        );
        return;
      }

      refreshing.value = true;

      await syncSubjects();
      await UserController.instance.fetchUserRecord();

      final localSubjects = await _subjectRepo.getLocalSubjects();

      final downloadedIds = localSubjects
          .where((s) => s['is_downloaded'] == 1)
          .map((s) => s['id'].toString())
          .toList();

      // download entrance test
      final subjects = localSubjects.map((s) => s['id'] as int).toList();
      await _syncRepository.downloadEntranceTests(subjects);

      if (downloadedIds.isNotEmpty) {
        await syncChapters(downloadedIds);
        await syncTests(downloadedIds);
        await syncQuestions(downloadedIds);
      }

      await SubjectsController.instance.syncSubjects();
    } catch (e) {
      rethrow;
    } finally {
      refreshing.value = false;
    }
  }

  Future<void> syncSubjects() async {
    final localSubjects = await _subjectRepo.getLocalSubjects();
    final remoteData = await _subjectRepo.getSupabaseSubjects();

    final remote = (remoteData as List)
        .map((e) => SubjectMoModel.fromJson(e))
        .toList();

    for (final s in remote) {
      final local = localSubjects.firstWhereOrNull((sub) => sub['id'] == s.id);

      if (local == null) {
        final map = s.toMap();
        map['is_downloaded'] = 0;
        _syncRepository.insertBatch('subjects', map);
      } else {
        _syncRepository.updateBatch(s, local['is_downloaded'] ?? 0);
      }
    }

    final remoteIds = remote.map((e) => e.id).toSet();

    for (final local in localSubjects) {
      if (!remoteIds.contains(local['id'])) {
        _syncRepository.deleteBatch(local);
      }
    }
    await _syncRepository.commitBatch();

    await SubjectsController.instance.loadLocalSubjects();
  }

  Future<void> syncChapters(List<String> subjectIds) async {
    final remoteData = await _syncRepository.getBySubjectId(
      'chapters',
      subjectIds,
    );

    final remote = (remoteData as List)
        .map((e) => ChapterModel.fromJson(e))
        .toList();

    for (final c in remote) {
      _syncRepository.insertBatch('chapters', c.toMap());
    }

    await _syncRepository.commitBatch();
  }

  Future<void> syncTests(List<String> subjectIds) async {
    final remoteData = await _syncRepository.getBySubjectId(
      'tests',
      subjectIds,
    );

    final remote = (remoteData as List)
        .map((e) => TestModel.fromJson(e))
        .toList();

    for (final t in remote) {
      _syncRepository.insertBatch('tests', t.toMap());
    }

    await _syncRepository.commitBatch();
  }

  Future<void> syncQuestions(List<String> subjectIds) async {
    final remoteData = await _syncRepository.getBySubjectId(
      'questions',
      subjectIds,
    );
    final remote = (remoteData as List)
        .map((e) => QuestionModel.fromJson(e))
        .toList();

    final Set<String> imageUrls = {};
    final Set<int> passageIds = {};

    for (final q in remote) {
      _syncRepository.insertBatch('questions', q.toMap());

      if (q.passageId != null) {
        passageIds.add(q.passageId!);
      }

      if (q.imageUrl != null && q.imageUrl!.isNotEmpty) {
        imageUrls.add(q.imageUrl!);
      }
    }

    await _syncRepository.commitBatch();

    if (passageIds.isNotEmpty) {
      await syncPassages(passageIds.toList());
    }

    if (imageUrls.isNotEmpty) {
      await AppHelperFuntions.downloadImages(imageUrls);
    }
  }

  Future<void> syncPassages(List<int> passageIds) async {
    try {
      final remoteData = await _syncRepository.getPassages(passageIds);

      final remote = (remoteData as List)
          .map((e) => PassageModel.fromMap(e))
          .toList();

      for (final p in remote) {
        _syncRepository.insertBatch('passages', p.toMap());
      }

      await _syncRepository.commitBatch();
    } catch (e) {
      rethrow;
    }
  }
}
