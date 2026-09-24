import 'dart:io';
import 'package:get/get.dart';
import 'package:matricmate/data/repositories/notes/notes_repository.dart';
import 'package:matricmate/features/notes/models/note_model.dart';
import 'package:matricmate/features/notes/services/note_download_service.dart';
import 'package:matricmate/features/personalization/controllers/user_controller.dart';
import 'package:matricmate/routes/app_routes.dart';
import 'package:matricmate/utils/exceptions/exception_handler.dart';
import 'package:matricmate/utils/helpers/test_access_helper.dart';
import 'package:matricmate/utils/helpers/toast_helper.dart';
import 'package:matricmate/utils/network_manager/network_manager.dart';

class NotesController extends GetxController {
  static NotesController get instance => Get.find();

  final NotesRepository _repo = NotesRepository();
  final NoteDownloadService _downloadService = NoteDownloadService.instance;

  final RxList<NoteModel> subjectNotes = <NoteModel>[].obs;
  final RxBool isLoading = false.obs;

  // Individual download progress: noteId -> progress (0.0 to 1.0)
  final RxMap<int, double> downloadProgress = <int, double>{}.obs;
  final RxMap<int, bool> isDownloading = <int, bool>{}.obs;

  // Grade-level bulk download progress: grade -> progress (0.0 to 1.0)
  final RxMap<int, double> gradeDownloadProgress = <int, double>{}.obs;
  final RxMap<int, bool> isGradeDownloading = <int, bool>{}.obs;

  late String title;
  late int subjectId;
  late bool isCommon;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments ?? {};
    title = args['title'] ?? args['subject'] ?? 'Subject Notes';
    subjectId = args['id'] ?? args['subject_id'] ?? 0;
    isCommon = args['is_common'] == true ||
        title.toLowerCase() == 'sat' ||
        title.toLowerCase() == 'english';

    loadSubjectNotes();
  }

  /// Loads notes from local SQLite first, then refreshes from remote if connected.
  Future<void> loadSubjectNotes({bool forceRemote = false}) async {
    try {
      isLoading.value = true;

      // 1. Paint immediately from local SQLite
      final local = await _repo.getLocalNotes(subjectId);
      // Validate that files recorded as downloaded actually exist on disk
      final validated = _validateLocalFiles(local);
      subjectNotes.assignAll(validated);

      // 2. Fetch metadata from Supabase if online or forced
      final isConnected = await NetworkManager.instance.isConnected();
      if (isConnected) {
        final remote = await _repo.fetchRemoteNotes(subjectId);
        if (remote.isNotEmpty) {
          await _repo.saveNotesBatch(remote);
          final updated = await _repo.getLocalNotes(subjectId);
          subjectNotes.assignAll(_validateLocalFiles(updated));
        }
      }
    } catch (e) {
      AppExceptionHandler.handleResponse(e);
    } finally {
      isLoading.value = false;
    }
  }

  /// Verifies whether downloaded files still exist on disk.
  List<NoteModel> _validateLocalFiles(List<NoteModel> list) {
    return list.map((note) {
      if (note.isDownloaded && note.localFilePath != null) {
        final exists = File(note.localFilePath!).existsSync();
        if (!exists) {
          return note.copyWith(isDownloaded: false, localFilePath: null);
        }
      }
      return note;
    }).toList();
  }

  /// Filter notes by grade
  List<NoteModel> getNotesByGrade(int grade) {
    if (isCommon) return subjectNotes;
    return subjectNotes.where((n) => n.grade == grade).toList();
  }

  /// Download a single note
  Future<void> downloadNote(NoteModel note) async {
    if (isDownloading[note.id] == true) return;

    final user = UserController.instance.user.value;
    if (note.isPremium && !user.isActive) {
      TestAccessHelper.openPremiumSheet(user: user);
      return;
    }

    try {
      final isConnected = await NetworkManager.instance.isConnected();
      if (!isConnected) {
        ToastHelper.warning('No Internet connection!');
        return;
      }

      isDownloading[note.id] = true;
      downloadProgress[note.id] = 0.05;

      final localPath = await _downloadService.downloadNote(
        note: note,
        onProgress: (p) => downloadProgress[note.id] = p,
      );

      // Update in reactive list
      final idx = subjectNotes.indexWhere((n) => n.id == note.id);
      if (idx != -1) {
        subjectNotes[idx] = note.copyWith(
          isDownloaded: true,
          localFilePath: localPath,
          downloadedAt: DateTime.now().toIso8601String(),
        );
      }

      ToastHelper.success('${note.title} downloaded!');
    } catch (e) {
      AppExceptionHandler.handleResponse(e);
    } finally {
      isDownloading[note.id] = false;
      downloadProgress.remove(note.id);
    }
  }

  /// Bulk download all undownloaded notes in a grade sequentially
  Future<void> downloadAllGradeNotes(int grade) async {
    if (isGradeDownloading[grade] == true) return;

    final user = UserController.instance.user.value;
    final gradeNotes = getNotesByGrade(grade);
    final toDownload = gradeNotes.where((n) => !n.isDownloaded).toList();

    if (toDownload.isEmpty) {
      ToastHelper.info('All Grade $grade notes are already downloaded!');
      return;
    }

    final hasPremiumNotes = toDownload.any((n) => n.isPremium);
    if (hasPremiumNotes && !user.isActive) {
      TestAccessHelper.openPremiumSheet(user: user);
      return;
    }

    final isConnected = await NetworkManager.instance.isConnected();
    if (!isConnected) {
      ToastHelper.warning('No Internet connection!');
      return;
    }

    isGradeDownloading[grade] = true;
    gradeDownloadProgress[grade] = 0.01;

    try {
      for (int i = 0; i < toDownload.length; i++) {
        final note = toDownload[i];
        isDownloading[note.id] = true;
        downloadProgress[note.id] = 0.1;

        try {
          final localPath = await _downloadService.downloadNote(
            note: note,
            onProgress: (p) => downloadProgress[note.id] = p,
          );

          final idx = subjectNotes.indexWhere((n) => n.id == note.id);
          if (idx != -1) {
            subjectNotes[idx] = note.copyWith(
              isDownloaded: true,
              localFilePath: localPath,
              downloadedAt: DateTime.now().toIso8601String(),
            );
          }
        } finally {
          isDownloading[note.id] = false;
          downloadProgress.remove(note.id);
        }

        gradeDownloadProgress[grade] = (i + 1) / toDownload.length;
      }

      ToastHelper.success('Grade $grade notes downloaded!');
    } catch (e) {
      AppExceptionHandler.handleResponse(e);
    } finally {
      isGradeDownloading[grade] = false;
      gradeDownloadProgress.remove(grade);
    }
  }

  /// Delete a downloaded note from device storage
  Future<void> deleteDownloadedNote(NoteModel note) async {
    try {
      await _downloadService.deleteNoteFile(note.id);
      final idx = subjectNotes.indexWhere((n) => n.id == note.id);
      if (idx != -1) {
        subjectNotes[idx] = note.copyWith(
          isDownloaded: false,
          localFilePath: null,
          downloadedAt: null,
        );
      }
      ToastHelper.info('${note.title} removed from device');
    } catch (e) {
      AppExceptionHandler.handleResponse(e);
    }
  }

  /// Open note detail or directly into reader
  void openNote(NoteModel note) {
    final user = UserController.instance.user.value;
    if (note.isPremium && !user.isActive) {
      TestAccessHelper.openPremiumSheet(user: user);
      return;
    }

    Get.toNamed(
      Routes.noteDetail,
      arguments: {
        'note': note,
        'subject_title': title,
        'subject_id': subjectId,
        'is_common': isCommon,
      },
    );
  }
}
