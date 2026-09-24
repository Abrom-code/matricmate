import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:get/get.dart';
import 'package:matricmate/features/exam/models/test_model.dart';
import 'package:matricmate/features/notes/controllers/notes_controller.dart';
import 'package:matricmate/features/notes/models/note_model.dart';
import 'package:matricmate/features/notes/services/note_download_service.dart';
import 'package:matricmate/routes/app_routes.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

class NoteReaderScreen extends StatefulWidget {
  const NoteReaderScreen({super.key});

  @override
  State<NoteReaderScreen> createState() => _NoteReaderScreenState();
}

class _NoteReaderScreenState extends State<NoteReaderScreen> {
  late NoteModel note;
  late String subjectTitle;
  List<TestModel> chapterTests = [];

  int _currentPage = 0;
  int _totalPages = 0;
  bool _isReady = false;
  bool _nightMode = false;
  bool _hasPromptedCompletion = false;

  String? _resolvedFilePath;
  bool _isLoadingFile = true;
  String? _fileError;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments ?? {};
    note = args['note'] as NoteModel;
    subjectTitle = args['subject_title'] ?? 'Subject';
    if (args['chapter_tests'] != null) {
      chapterTests = List<TestModel>.from(args['chapter_tests']);
    }

    _resolveFile();
  }

  /// Resolves the file to read. Offline-first: opens local file directly if available.
  /// Otherwise requests a temporary signed URL from Supabase and streams into cache.
  Future<void> _resolveFile() async {
    // 1. Offline copy check
    if (note.isDownloaded &&
        note.localFilePath != null &&
        File(note.localFilePath!).existsSync() &&
        File(note.localFilePath!).lengthSync() > 0) {
      if (mounted) {
        setState(() {
          _resolvedFilePath = note.localFilePath;
          _isLoadingFile = false;
          _fileError = null;
        });
      }
      return;
    }

    // 2. Online streaming via Cloudflare R2 temporary signed URL
    if (mounted) {
      setState(() {
        _isLoadingFile = true;
        _fileError = null;
      });
    }

    try {
      final cachedPath = await NoteDownloadService.instance.cacheNoteForViewing(
        note: note,
      );
      if (mounted) {
        setState(() {
          _resolvedFilePath = cachedPath;
          _isLoadingFile = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _fileError = e.toString();
          _isLoadingFile = false;
        });
      }
    }
  }

  void _showCompletionSheet() {
    if (_hasPromptedCompletion || !mounted) return;
    _hasPromptedCompletion = true;

    final dark = AppHelperFunctions.isDark(context);

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.fromLTRB(22, 16, 22, 28),
        decoration: BoxDecoration(
          color: dark ? AppColors.darkCard : AppColors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: Border.all(
            color: dark ? AppColors.darkBorder : AppColors.borderPrimary,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 18),
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF10B981),
                  size: 32,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              note.grade == 0 ? 'Reading Completed!' : 'Chapter Completed!',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w900,
                color: dark ? AppColors.white : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              note.chapterId != null
                  ? 'You finished reading ${note.title}. Ready to test your retention with practice questions?'
                  : 'You finished reading ${note.title}. Great job reviewing your concepts!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: dark ? AppColors.darkGrey : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 22),
            if (note.chapterId != null) ...[
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () {
                    Get.back();
                    Get.toNamed(
                      Routes.testLists,
                      arguments: {
                        'subject_id': note.subjectId,
                        'grade': note.grade,
                        'subject': subjectTitle,
                        'chapter': note.title,
                        'chapter_id': note.chapterId,
                        'chapter_number': note.chapterNumber,
                      },
                    );
                  },
                  icon: const Icon(Icons.quiz_rounded, size: 18),
                  label: const Text(
                    'Practice Chapter Tests Now',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
            SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  side: BorderSide(
                    color: dark ? AppColors.darkInputBorder : AppColors.borderPrimary,
                  ),
                ),
                onPressed: () {
                  Get.back();
                  Get.back(); // Return to note list
                },
                child: Text(
                  'Back to Notes List',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: dark ? AppColors.white : AppColors.textPrimary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final dark = AppHelperFunctions.isDark(context);

    return Scaffold(
      backgroundColor: _nightMode
          ? const Color(0xFF121212)
          : (dark ? AppColors.black : const Color(0xFFE2E8F0)),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 4),
          child: IconButton(
            onPressed: Get.back,
            icon: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 16,
                  color: AppColors.white,
                ),
              ),
            ),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              note.title,
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              _totalPages > 0
                  ? 'Page ${_currentPage + 1} of $_totalPages'
                  : 'Reading note...',
              style: const TextStyle(
                color: Color(0xFFD1FAE5),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          // Night mode toggle
          IconButton(
            tooltip: _nightMode ? 'Light Mode' : 'Night Mode',
            onPressed: () => setState(() => _nightMode = !_nightMode),
            icon: Icon(
              _nightMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              color: AppColors.white,
              size: 20,
            ),
          ),
          // Save for offline action if not yet downloaded
          Obx(() {
            final liveNote = NotesController.instance.subjectNotes
                    .firstWhereOrNull((n) => n.id == note.id) ??
                note;
            final isDownloading =
                NotesController.instance.isDownloading[note.id] ?? false;

            if (liveNote.isDownloaded) {
              return const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Center(
                  child: Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFFD1FAE5),
                    size: 20,
                  ),
                ),
              );
            }

            return IconButton(
              tooltip: 'Save note for offline reading',
              onPressed: isDownloading
                  ? null
                  : () => NotesController.instance.downloadNote(note),
              icon: isDownloading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.white,
                      ),
                    )
                  : const Icon(
                      Icons.download_rounded,
                      color: AppColors.white,
                      size: 20,
                    ),
            );
          }),
          // Practice quick button
          if (note.chapterId != null)
            IconButton(
              tooltip: 'Practice chapter tests',
              onPressed: () {
                Get.toNamed(
                  Routes.testLists,
                  arguments: {
                    'subject_id': note.subjectId,
                    'grade': note.grade,
                    'subject': subjectTitle,
                    'chapter': note.title,
                    'chapter_id': note.chapterId,
                    'chapter_number': note.chapterNumber,
                  },
                );
              },
              icon: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.quiz_rounded, size: 14, color: AppColors.white),
                    SizedBox(width: 4),
                    Text(
                      'Test',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      body: _isLoadingFile
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: AppColors.primary),
                  const SizedBox(height: 16),
                  Text(
                    'Loading note...',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: dark ? AppColors.textWhite : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            )
          : _fileError != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(28.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          size: 46,
                          color: AppColors.error,
                        ),
                        const SizedBox(height: 14),
                        Text(
                          _fileError!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13.5,
                            height: 1.4,
                            color: dark
                                ? AppColors.textWhite
                                : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 18),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: _resolveFile,
                          icon: const Icon(Icons.refresh_rounded, size: 18),
                          label: const Text('Try Again'),
                        ),
                      ],
                    ),
                  ),
                )
              : _resolvedFilePath == null
                  ? const Center(
                      child: Text(
                        'Note file not found on device.',
                        style: TextStyle(fontSize: 14),
                      ),
                    )
                  : Stack(
                      children: [
                        PDFView(
                          filePath: _resolvedFilePath,
                          enableSwipe: true,
                          swipeHorizontal: false,
                          autoSpacing: true,
                          pageFling: true,
                          nightMode: _nightMode,
                          onRender: (pages) {
                            setState(() {
                              _totalPages = pages ?? 0;
                              _isReady = true;
                            });
                          },
                          onViewCreated: (_) {},
                          onPageChanged: (page, total) {
                            setState(() {
                              _currentPage = page ?? 0;
                              _totalPages = total ?? _totalPages;
                            });

                            // Trigger completion when reaching the last page
                            if (_totalPages > 0 &&
                                _currentPage >= _totalPages - 1 &&
                                !_hasPromptedCompletion) {
                              Future.delayed(
                                const Duration(milliseconds: 600),
                                _showCompletionSheet,
                              );
                            }
                          },
                        ),
                        if (!_isReady)
                          const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primary,
                            ),
                          ),
                      ],
                    ),
    );
  }
}
