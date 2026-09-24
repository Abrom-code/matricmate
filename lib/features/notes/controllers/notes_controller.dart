import 'dart:io';
import 'package:get/get.dart';
import 'package:matricmate/common/widgets/dialogs/download_progress_dialog.dart';
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

  // Batch download state & cancellation for full-screen dialog
  DownloadCancellationToken? _currentCancellationToken;
  final RxDouble batchDownloadProgress = 0.0.obs;
  final RxString batchDownloadCurrentItem = ''.obs;
  final RxInt batchDownloadCompletedCount = 0.obs;
  final RxInt batchDownloadTotalCount = 0.obs;
  final RxString batchDownloadTitle = ''.obs;
  final RxInt activeBatchGrade = (-1).obs;

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
      if (subjectNotes.isEmpty) {
        isLoading.value = true;
      }

      // 1. Paint immediately from local SQLite (zero-delay offline first)
      final local = await _repo.getLocalNotes(subjectId);
      final validated = _validateLocalFiles(local);
      subjectNotes.assignAll(validated);

      // 2. Fetch metadata from Supabase if online
      final isConnected = await NetworkManager.instance.isConnected();
      if (isConnected) {
        final remote = await _repo.fetchRemoteNotes(subjectId);
        await _repo.saveNotesBatch(
          remote,
          subjectId: subjectId,
          pruneDeleted: true,
        );
        final updated = await _repo.getLocalNotes(subjectId);
        subjectNotes.assignAll(_validateLocalFiles(updated));
      } else if (forceRemote) {
        ToastHelper.warning("You're offline. Showing saved notes.");
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

    // Mark as downloading immediately so the UI updates without delay
    isDownloading[note.id] = true;

    try {
      final isConnected = await NetworkManager.instance.isConnected();
      if (!isConnected) {
        ToastHelper.warning('No Internet connection!');
        return;
      }

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

  /// Cancels the currently active download process (batch or single)
  void cancelCurrentDownload() {
    if (_currentCancellationToken != null &&
        !_currentCancellationToken!.isCancelled) {
      _currentCancellationToken!.cancel();
    }
    DownloadProgressDialog.hide();
    isGradeDownloading.clear();
    gradeDownloadProgress.clear();
    isDownloading.clear();
    downloadProgress.clear();
    activeBatchGrade.value = -1;
    batchDownloadProgress.value = 0.0;
    batchDownloadCurrentItem.value = '';
    batchDownloadCompletedCount.value = 0;
    batchDownloadTotalCount.value = 0;
    ToastHelper.info('Download cancelled');
  }

  /// Opens or re-opens the full screen download progress dialog if a batch is active
  void showActiveDownloadProgressDialog() {
    if (activeBatchGrade.value != -1 && batchDownloadTotalCount.value > 0) {
      DownloadProgressDialog.show(
        title: batchDownloadTitle.value,
        subtitle: title,
        progress: batchDownloadProgress,
        currentItem: batchDownloadCurrentItem,
        completedCount: batchDownloadCompletedCount,
        totalCount: batchDownloadTotalCount.value,
        onCancel: cancelCurrentDownload,
      );
    }
  }

  /// Bulk download all undownloaded notes in a grade sequentially with full screen progress and cancel support
  Future<void> downloadAllGradeNotes(int grade) async {
    if (isGradeDownloading[grade] == true) {
      // Re-open progress dialog if already downloading
      showActiveDownloadProgressDialog();
      return;
    }

    final user = UserController.instance.user.value;
    final gradeNotes = getNotesByGrade(grade);
    final toDownload = gradeNotes.where((n) => !n.isDownloaded).toList();
    final gradeLabel = grade == 0 ? (isCommon ? 'Subject' : 'General') : 'Grade $grade';

    if (toDownload.isEmpty) {
      ToastHelper.info('All $gradeLabel notes are already downloaded!');
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

    _currentCancellationToken = DownloadCancellationToken();
    isGradeDownloading[grade] = true;
    activeBatchGrade.value = grade;
    gradeDownloadProgress[grade] = 0.0;

    batchDownloadTitle.value = 'Downloading $gradeLabel Notes';
    batchDownloadProgress.value = 0.0;
    batchDownloadCompletedCount.value = 0;
    batchDownloadTotalCount.value = toDownload.length;
    batchDownloadCurrentItem.value = toDownload.first.title;

    DownloadProgressDialog.show(
      title: 'Downloading $gradeLabel Notes',
      subtitle: title,
      progress: batchDownloadProgress,
      currentItem: batchDownloadCurrentItem,
      completedCount: batchDownloadCompletedCount,
      totalCount: toDownload.length,
      onCancel: cancelCurrentDownload,
    );

    final List<({int noteId, String localPath})> downloadedEntries = [];
    try {
      for (int i = 0; i < toDownload.length; i++) {
        if (_currentCancellationToken?.isCancelled == true) break;

        final note = toDownload[i];
        batchDownloadCurrentItem.value = note.title;
        batchDownloadCompletedCount.value = i;
        isDownloading[note.id] = true;
        downloadProgress[note.id] = 0.0;

        try {
          final localPath = await _downloadService.downloadNote(
            note: note,
            cancellationToken: _currentCancellationToken,
            skipDbWrite: true,
            onProgress: (p) {
              downloadProgress[note.id] = p;
              final overallProgress = (i + p) / toDownload.length;
              gradeDownloadProgress[grade] = overallProgress;
              batchDownloadProgress.value = overallProgress;
            },
          );

          downloadedEntries.add((noteId: note.id, localPath: localPath));

          final idx = subjectNotes.indexWhere((n) => n.id == note.id);
          if (idx != -1) {
            subjectNotes[idx] = note.copyWith(
              isDownloaded: true,
              localFilePath: localPath,
              downloadedAt: DateTime.now().toIso8601String(),
            );
          }
        } catch (e) {
          if (_currentCancellationToken?.isCancelled == true) {
            break;
          }
          rethrow;
        } finally {
          isDownloading[note.id] = false;
          downloadProgress.remove(note.id);
        }

        final nextProgress = (i + 1) / toDownload.length;
        gradeDownloadProgress[grade] = nextProgress;
        batchDownloadProgress.value = nextProgress;
        batchDownloadCompletedCount.value = i + 1;
      }

      if (downloadedEntries.isNotEmpty) {
        await _repo.markMultipleNotesDownloaded(downloadedEntries);
      }

      if (_currentCancellationToken?.isCancelled != true) {
        DownloadProgressDialog.hide();
        ToastHelper.success('$gradeLabel notes downloaded!');
      }
    } catch (e) {
      if (downloadedEntries.isNotEmpty) {
        try {
          await _repo.markMultipleNotesDownloaded(downloadedEntries);
        } catch (_) {}
      }
      DownloadProgressDialog.hide();
      if (_currentCancellationToken?.isCancelled != true) {
        AppExceptionHandler.handleResponse(e);
      }
    } finally {
      isGradeDownloading[grade] = false;
      gradeDownloadProgress.remove(grade);
      activeBatchGrade.value = -1;
      _currentCancellationToken = null;
    }
  }

  /// Delete a downloaded note from device storage
  Future<void> deleteDownloadedNote(NoteModel note) async {
    try {
      await _downloadService.deleteNoteFile(note.id);
      final idx = subjectNotes.indexWhere((n) => n.id == note.id);
      if (idx != -1) {
        // Always use the current list entry, not the stale passed-in snapshot
        subjectNotes[idx] = subjectNotes[idx].copyWith(
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

  /// Delete all downloaded notes in a grade from device storage
  Future<void> deleteAllGradeNotes(int grade) async {
    final gradeLabel =
        grade == 0 ? (isCommon ? 'Subject' : 'General') : 'Grade $grade';
    try {
      await _repo.deleteAllDownloadedNotesForGrade(subjectId, grade);

      for (int i = 0; i < subjectNotes.length; i++) {
        if (subjectNotes[i].grade == grade || (isCommon && grade == 0)) {
          subjectNotes[i] = subjectNotes[i].copyWith(
            isDownloaded: false,
            localFilePath: null,
            downloadedAt: null,
          );
        }
      }

      ToastHelper.info('All $gradeLabel notes removed from device');
    } catch (e) {
      AppExceptionHandler.handleResponse(e);
    }
  }

  /// Mark a note as completed both in local SQLite and reactive state
  Future<void> markNoteCompleted(int noteId) async {
    try {
      await _repo.markNoteCompleted(noteId);
      final idx = subjectNotes.indexWhere((n) => n.id == noteId);
      if (idx != -1) {
        subjectNotes[idx] = subjectNotes[idx].copyWith(
          isCompleted: true,
          completedAt: DateTime.now().toIso8601String(),
        );
      }
    } catch (_) {}
  }

  /// Open note directly into reader
  void openNote(NoteModel note) {
    // Always use the live note from subjectNotes to reflect latest state
    final liveNote = subjectNotes.firstWhereOrNull((n) => n.id == note.id) ?? note;

    final user = UserController.instance.user.value;
    if (liveNote.isPremium && !user.isActive) {
      TestAccessHelper.openPremiumSheet(user: user);
      return;
    }

    if (!liveNote.isDownloaded) {
      downloadNote(liveNote);
      return;
    }

    Get.toNamed(
      Routes.noteReader,
      arguments: {
        'note': liveNote,
        'subject_title': title,
        'subject_id': subjectId,
        'is_common': isCommon,
      },
    );
  }
}
