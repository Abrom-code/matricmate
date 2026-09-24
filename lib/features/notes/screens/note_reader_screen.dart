import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:get/get.dart';
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

  int _currentPage = 0;
  int _totalPages = 0;
  bool _isReady = false;
  bool _nightMode = false;
  bool _hasPromptedCompletion = false;
  bool _isLandscape = false;

  PDFViewController? _pdfViewController;
  bool _isDraggingSlider = false;
  double? _dragHandleTop;
  int _sliderDragPage = 0;
  int _lastJumpingPage = -1;
  bool _showSliderBubble = false;
  Timer? _bubbleHideTimer;
  Timer? _pageThrottleTimer;
  int? _pendingTargetPage;

  String? _resolvedFilePath;
  bool _isLoadingFile = true;
  String? _fileError;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments ?? {};
    note = args['note'] as NoteModel;
    subjectTitle = args['subject_title'] ?? 'Subject';

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

  @override
  void dispose() {
    _bubbleHideTimer?.cancel();
    _pageThrottleTimer?.cancel();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  void _toggleOrientation() {
    setState(() {
      _isLandscape = !_isLandscape;
    });
    if (_isLandscape) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    }
  }

  void _onSliderDrag(
      double localY, double availableTrack, double handleHeight, double topMargin) {
    if (_totalPages <= 1 || availableTrack <= 0) return;
    _bubbleHideTimer?.cancel();

    final clampedY =
        (localY - topMargin - handleHeight / 2).clamp(0.0, availableTrack);
    final fraction = (clampedY / availableTrack).clamp(0.0, 1.0);
    final targetPage =
        (fraction * (_totalPages - 1)).round().clamp(0, _totalPages - 1);

    setState(() {
      _isDraggingSlider = true;
      _showSliderBubble = true;
      _dragHandleTop = clampedY;
      _sliderDragPage = targetPage;
      _currentPage = targetPage;
    });

    if (targetPage != _lastJumpingPage) {
      _pendingTargetPage = targetPage;
      if (_pageThrottleTimer == null || !_pageThrottleTimer!.isActive) {
        _lastJumpingPage = targetPage;
        _pdfViewController?.setPage(targetPage);
        _pageThrottleTimer = Timer(const Duration(milliseconds: 60), () {
          if (_pendingTargetPage != null &&
              _pendingTargetPage != _lastJumpingPage) {
            _lastJumpingPage = _pendingTargetPage!;
            _pdfViewController?.setPage(_pendingTargetPage!);
          }
        });
      }
    }
  }

  void _onSliderDragEnd() {
    _pageThrottleTimer?.cancel();
    if (_pendingTargetPage != null && _pendingTargetPage != _lastJumpingPage) {
      _lastJumpingPage = _pendingTargetPage!;
      _pdfViewController?.setPage(_pendingTargetPage!);
    }
    _bubbleHideTimer?.cancel();
    _bubbleHideTimer = Timer(const Duration(milliseconds: 1400), () {
      if (mounted) {
        setState(() {
          _isDraggingSlider = false;
          _showSliderBubble = false;
          _dragHandleTop = null;
        });
      }
    });
  }

  Widget _buildRightSlider(double maxHeight) {
    if (!_isReady || _totalPages <= 1) return const SizedBox.shrink();

    const double topMargin = 16.0;
    const double bottomMargin = 24.0;
    const double handleHeight = 34.0;
    const double handleWidth = 26.0;
    final double availableTrack =
        (maxHeight - handleHeight - topMargin - bottomMargin).clamp(0.0, maxHeight);

    final double normalFraction = _totalPages > 1
        ? (_currentPage / (_totalPages - 1)).clamp(0.0, 1.0)
        : 0.0;
    final double handleTop =
        topMargin + (_dragHandleTop ?? (normalFraction * availableTrack));
    final displayPage =
        (_isDraggingSlider ? _sliderDragPage : _currentPage) + 1;

    return Positioned(
      top: 0,
      right: 0,
      bottom: 0,
      width: 44,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onVerticalDragStart: (details) {
          _onSliderDrag(
              details.localPosition.dy, availableTrack, handleHeight, topMargin);
        },
        onVerticalDragUpdate: (details) {
          _onSliderDrag(
              details.localPosition.dy, availableTrack, handleHeight, topMargin);
        },
        onVerticalDragEnd: (_) => _onSliderDragEnd(),
        onTapDown: (details) {
          _onSliderDrag(
              details.localPosition.dy, availableTrack, handleHeight, topMargin);
        },
        onTapUp: (_) => _onSliderDragEnd(),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            AnimatedPositioned(
              duration: _isDraggingSlider
                  ? Duration.zero
                  : const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              top: handleTop,
              right: 0,
              child: AnimatedOpacity(
                opacity: (_isDraggingSlider || _showSliderBubble) ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 180),
                child: AnimatedScale(
                  scale: _isDraggingSlider ? 1.08 : 1.0,
                  duration: const Duration(milliseconds: 120),
                  child: Container(
                    width: handleWidth,
                    height: handleHeight,
                    alignment: Alignment.center,
                    padding: const EdgeInsets.only(left: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xF01E1E1E),
                      borderRadius: const BorderRadius.horizontal(
                        left: Radius.circular(17),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.35),
                          blurRadius: 6,
                          offset: const Offset(-1, 1.5),
                        ),
                      ],
                    ),
                    child: Text(
                      '$displayPage',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.0,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCompletionSheet() {
    if (_hasPromptedCompletion || !mounted) return;
    _hasPromptedCompletion = true;

    // Mark note as completed in SQLite & reactive state
    NotesController.instance.markNoteCompleted(note.id);

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
          // Orientation toggle button (Portrait / Landscape)
          IconButton(
            tooltip: _isLandscape ? 'Portrait Mode' : 'Landscape Mode',
            onPressed: _toggleOrientation,
            icon: Icon(
              _isLandscape
                  ? Icons.stay_current_landscape_rounded
                  : Icons.stay_current_portrait_rounded,
              color: AppColors.white,
              size: 20,
            ),
          ),
          // Save for offline action if not yet downloaded (check icon removed)
          Obx(() {
            final liveNote = NotesController.instance.subjectNotes
                    .firstWhereOrNull((n) => n.id == note.id) ??
                note;
            final isDownloading =
                NotesController.instance.isDownloading[note.id] ?? false;

            if (liveNote.isDownloaded) {
              return const SizedBox.shrink();
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
              icon: const Icon(
                Icons.quiz_rounded,
                color: AppColors.white,
                size: 20,
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
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        return Stack(
                          children: [
                            PDFView(
                              filePath: _resolvedFilePath,
                              enableSwipe: true,
                              swipeHorizontal: false,
                              autoSpacing: false,
                              pageFling: false,
                              pageSnap: false,
                              fitPolicy: FitPolicy.WIDTH,
                              nightMode: _nightMode,
                              onRender: (pages) {
                                setState(() {
                                  _totalPages = pages ?? 0;
                                  _isReady = true;
                                });
                              },
                              onViewCreated: (controller) {
                                _pdfViewController = controller;
                              },
                              onPageChanged: (page, total) {
                                setState(() {
                                  _currentPage = page ?? 0;
                                  _totalPages = total ?? _totalPages;
                                  if (!_isDraggingSlider) {
                                    _showSliderBubble = true;
                                  }
                                });

                                if (!_isDraggingSlider) {
                                  _bubbleHideTimer?.cancel();
                                  _bubbleHideTimer = Timer(
                                    const Duration(milliseconds: 1500),
                                    () {
                                      if (mounted && !_isDraggingSlider) {
                                        setState(() {
                                          _showSliderBubble = false;
                                        });
                                      }
                                    },
                                  );
                                }

                                // Trigger completion when reaching the last page
                                if (_totalPages > 0 &&
                                    _currentPage >= _totalPages - 1 &&
                                    !_hasPromptedCompletion) {
                                  NotesController.instance
                                      .markNoteCompleted(note.id);
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
                            // ── Right Side Fast-Scroll Slider & Bubble ─────────
                            _buildRightSlider(constraints.maxHeight),
                          ],
                        );
                      },
                    ),
    );
  }
}
