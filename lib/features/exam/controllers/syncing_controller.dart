import 'dart:convert';
import 'package:get/get.dart';
import 'package:matricmate/data/repositories/exam/subject_repository.dart';
import 'package:matricmate/data/repositories/exam/sync_repository.dart';
import 'package:matricmate/features/personalization/controller/user_controller.dart';
import 'package:matricmate/utils/exceptions/app_failure_model.dart';
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
      final isConnectd = await NetworkManager.instance.hasRealInternet();
      if (!isConnectd) {
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

      if (downloadedIds.isNotEmpty) {
        await syncChapters(downloadedIds);
        await syncTests(downloadedIds);
        await syncQuestions(downloadedIds);
      }
      ToastHelper.success("Success", "All Subjects are refreshed");
    } catch (e) {
      if (e is AppFailure) {
        ToastHelper.error(e.title, e.message);
      } else {
        ToastHelper.error("Unexpected Error", e.toString());
      }
    } finally {
      refreshing.value = false;
    }
  }

  //  SYNC SUBJECTS
  Future<void> syncSubjects() async {
    try {
      final localSubjects = await _subjectRepo.getLocalSubjects();
      final remoteData = await _subjectRepo.getSupabaseSubjects();
      final remote = (remoteData as List)
          .map((e) => SubjectMoModel.fromJson(e))
          .toList();

      for (final s in remote) {
        final local = localSubjects.firstWhereOrNull(
          (sub) => sub['id'] == s.id,
        );

        if (local == null) {
          _syncRepository.insertBatch('subjects', s.toMap());
        } else {
          _syncRepository.updateBatch(s, local);
        }
      }

      final remoteIds = remote.map((e) => e.id).toSet();
      for (final local in localSubjects) {
        if (!remoteIds.contains(local['id'])) {
          _syncRepository.deleteBatch(local);
        }
      }

      await _syncRepository.commitBatch();
      SubjectsController.instance.syncSubjects();
    } catch (e) {
      throw e;
    }
  }

  //  SYNC CHAPTERS
  Future<void> syncChapters(List<String> subjectIds) async {
    try {
      final remoteData = await _syncRepository.getBySubjectId(
        'chapters',
        subjectIds,
      );
      final remote = (remoteData as List)
          .map((rc) => ChapterModel.fromJson(rc))
          .toList();

      for (final c in remote) {
        _syncRepository.insertBatch('chapters', c.toMap());
      }
      await _syncRepository.commitBatch();
    } catch (e) {
      throw e;
    }
  }

  //  SYNC TESTS
  Future<void> syncTests(List<String> subjectIds) async {
    try {
      final remoteData = await _syncRepository.getBySubjectId(
        'tests',
        subjectIds,
      );
      final remote = (remoteData as List)
          .map((rc) => TestModel.fromJson(rc))
          .toList();

      for (final t in remote) {
        _syncRepository.insertBatch('tests', t.toMap());
      }
      await _syncRepository.commitBatch();
    } catch (e) {
      throw e;
    }
  }

  //  SYNC QUESTIONS & PASSAGES
  Future<void> syncQuestions(List<String> subjectIds) async {
    try {
      final remoteData = await _syncRepository.getBySubjectId(
        'questions',
        subjectIds,
      );
      final remote = (remoteData as List).map(
        (rc) => QuestionModel.fromJson(rc),
      );

      final List<int> passageIds = [];

      for (final q in remote) {
        final questionMap = q.toMap();
        questionMap['options'] = jsonEncode(q.options);

        _syncRepository.insertBatch('questions', questionMap);

        if (q.passageId != null) {
          passageIds.add(q.passageId!);
        }
      }

      await _syncRepository.commitBatch();

      // Sync Passages referenced by these questions
      if (passageIds.isNotEmpty) {
        await syncPassages(passageIds.toSet().toList());
      }
    } catch (e) {
      throw e;
    }
  }

  //  SYNC PASSAGES
  Future<void> syncPassages(List<int> passageIds) async {
    try {
      final remoteData = await _syncRepository.getPassages(passageIds);

      final remote = (remoteData as List)
          .map((p) => PassageModel.fromJson(p))
          .toList();

      for (final p in remote) {
        _syncRepository.insertBatch('passages', p.toMap());
      }
      await _syncRepository.commitBatch();
    } catch (e) {
      throw e;
    }
  }
}
