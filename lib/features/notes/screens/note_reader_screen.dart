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

  // ── Page tracking (ValueNotifier to avoid rebuilding PDFView) ──────
  final ValueNotifier<int> _pageNotifier = ValueNotifier<int>(0);
  int _totalPages = 0;
  bool _isReady = false;
  bool _nightMode = false;
  bool _hasPromptedCompletion = false;
  bool _isLandscape = false;
  bool _isOnLastPage = false;
  bool _showCompletionPanel = false;

  PDFViewController? _pdfViewController;

  // ── Slider state ───────────────────────────────────────────────────
  bool _isDraggingSlider = false;
  double? _dragHandleTop;
  int _sliderDragPage = 0;
  int _lastJumpingPage = -1;
  bool _showSliderBubble = false;
  Timer? _bubbleHideTimer;
  Timer? _pageThrottleTimer;
  int? _pendingTargetPage;
  double _dragStartY = 0.0;
  double _dragStartHandleTop = 0.0;

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
    _pageNotifier.dispose();
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

  // ── Slider Handle Drag (only when user touches the handle) ─────────

  void _onHandleDragStart(DragStartDetails details, double currentHandleTop) {
    if (_totalPages <= 1) return;
    _bubbleHideTimer?.cancel();
    _pageThrottleTimer?.cancel();

    _dragStartY = details.globalPosition.dy;
    _dragStartHandleTop = currentHandleTop;

    setState(() {
      _isDraggingSlider = true;
      _showSliderBubble = true;
      _dragHandleTop = currentHandleTop;
      _sliderDragPage = _pageNotifier.value;
    });
  }

  void _onHandleDragUpdate(
      DragUpdateDetails details, double availableTrack, double topMargin) {
    if (_totalPages <= 1 || availableTrack <= 0) return;
    _bubbleHideTimer?.cancel();

    final deltaY = details.globalPosition.dy - _dragStartY;
    final newHandleTop = (_dragStartHandleTop + deltaY)
        .clamp(topMargin, topMargin + availableTrack);
    final fraction =
        ((newHandleTop - topMargin) / availableTrack).clamp(0.0, 1.0);
    final targetPage =
        (fraction * (_totalPages - 1)).round().clamp(0, _totalPages - 1);

    setState(() {
      _dragHandleTop = newHandleTop;
      _sliderDragPage = targetPage;
    });

    if (targetPage != _lastJumpingPage) {
      _pendingTargetPage = targetPage;
      if (_pageThrottleTimer == null || !_pageThrottleTimer!.isActive) {
        _lastJumpingPage = targetPage;
        _pdfViewController?.setPage(targetPage);
        _pageThrottleTimer = Timer(const Duration(milliseconds: 80), () {
          if (_pendingTargetPage != null &&
              _pendingTargetPage != _lastJumpingPage) {
            _lastJumpingPage = _pendingTargetPage!;
            _pdfViewController?.setPage(_pendingTargetPage!);
          }
        });
      }
    }
  }

  void _onHandleDragEnd() {
    _pageThrottleTimer?.cancel();
    if (_pendingTargetPage != null && _pendingTargetPage != _lastJumpingPage) {
      _lastJumpingPage = _pendingTargetPage!;
      _pdfViewController?.setPage(_pendingTargetPage!);
    }

    final finalPage = _pendingTargetPage ?? _lastJumpingPage;
    if (finalPage >= 0) {
      _pageNotifier.value = finalPage;
      final inLast3 = _totalPages > 0 &&
          finalPage >= (_totalPages - 3).clamp(0, _totalPages - 1);
      if (inLast3 != _showCompletionPanel) {
        setState(() => _showCompletionPanel = inLast3);
      }
      final onLast = _totalPages > 0 && finalPage >= _totalPages - 1;
      if (onLast && !_hasPromptedCompletion) {
        _triggerCompletion();
      }
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

  // ── Right-Side Slider Widget ───────────────────────────────────────

  Widget _buildRightSlider(double maxHeight) {
    if (!_isReady || _totalPages <= 1) return const SizedBox.shrink();

    const double topMargin = 16.0;
    const double bottomMargin = 24.0;
    const double handleHeight = 34.0;
    const double handleWidth = 26.0;
    final double availableTrack =
        (maxHeight - handleHeight - topMargin - bottomMargin)
            .clamp(0.0, maxHeight);

    // Use ValueListenableBuilder so only the slider rebuilds on page change,
    // not the entire Stack (which would force PDFView to re-composite).
    return ValueListenableBuilder<int>(
      valueListenable: _pageNotifier,
      builder: (context, currentPage, _) {
        final double normalFraction = _totalPages > 1
            ? (currentPage / (_totalPages - 1)).clamp(0.0, 1.0)
            : 0.0;
        final double handleTop =
            _dragHandleTop ?? (topMargin + (normalFraction * availableTrack));
        final displayPage =
            (_isDraggingSlider ? _sliderDragPage : currentPage) + 1;
        final isVisible = _isDraggingSlider || _showSliderBubble;

        return AnimatedPositioned(
          duration: _isDraggingSlider
              ? Duration.zero
              : const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          top: handleTop,
          right: 0,
          child: IgnorePointer(
            ignoring: !isVisible,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onVerticalDragStart: (details) =>
                  _onHandleDragStart(details, handleTop),
              onVerticalDragUpdate: (details) =>
                  _onHandleDragUpdate(details, availableTrack, topMargin),
              onVerticalDragEnd: (_) => _onHandleDragEnd(),
              onVerticalDragCancel: () => _onHandleDragEnd(),
              child: AnimatedOpacity(
                opacity: isVisible ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 180),
                child: Container(
                  width: handleWidth + 14,
                  height: handleHeight + 12,
                  alignment: Alignment.centerRight,
                  color: Colors.transparent,
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
          ),
        );
      },
    );
  }

  void _triggerCompletion() {
    if (_hasPromptedCompletion) return;
    _hasPromptedCompletion = true;
    NotesController.instance.markNoteCompleted(note.id);
  }

  // ── Test Button (slides up at bottom when last 3 pages left) ──────

  Widget _buildCompletionPanel() {
    // Only show test button if note has a chapter
    if (note.chapterId == null) return const SizedBox.shrink();

    return AnimatedSlide(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      offset: _showCompletionPanel ? Offset.zero : const Offset(0, 1.5),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 280),
        opacity: _showCompletionPanel ? 1.0 : 0.0,
        child: IgnorePointer(
          ignoring: !_showCompletionPanel,
          child: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          height: 48,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 4,
              shadowColor: AppColors.primary.withValues(alpha: 0.35),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
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
            icon: const Icon(Icons.quiz_rounded, size: 18),
            label: const Text(
              'Practice Tests',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    ),
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
                  ? 'Page ${_pageNotifier.value + 1} of $_totalPages'
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
          SizedBox(
            width: 36,
            child: IconButton(
              tooltip: _nightMode ? 'Light Mode' : 'Night Mode',
              onPressed: () => setState(() => _nightMode = !_nightMode),
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              icon: Icon(
                _nightMode ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                color: AppColors.white,
                size: 20,
              ),
            ),
          ),
          // Orientation toggle
          SizedBox(
            width: 36,
            child: IconButton(
              tooltip: _isLandscape ? 'Portrait Mode' : 'Landscape Mode',
              onPressed: _toggleOrientation,
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              icon: Icon(
                _isLandscape
                    ? Icons.crop_portrait_rounded
                    : Icons.screen_rotation_rounded,
                color: AppColors.white,
                size: 20,
              ),
            ),
          ),
          // Practice quick button
          if (note.chapterId != null)
            SizedBox(
              width: 36,
              child: IconButton(
                tooltip: 'Practice chapter tests',
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
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
            ),
          const SizedBox(width: 4),
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
                              autoSpacing: true,
                              pageFling: false,
                              pageSnap: false,
                              fitPolicy: FitPolicy.WIDTH,
                              nightMode: _nightMode,
                              onRender: (pages) {
                                final total = pages ?? 0;
                                final initialPage = _pageNotifier.value;
                                final inLast3 = total > 0 &&
                                    initialPage >=
                                        (total - 3).clamp(0, total - 1);
                                setState(() {
                                  _totalPages = total;
                                  _isReady = true;
                                  if (inLast3) {
                                    _showCompletionPanel = true;
                                  }
                                });
                              },
                              onViewCreated: (controller) {
                                _pdfViewController = controller;
                              },
                              onPageChanged: (page, total) {
                                if (_isDraggingSlider) return;
                                final newPage = page ?? 0;
                                final newTotal = total ?? _totalPages;

                                // Update total if changed (rare, only on render)
                                if (_totalPages != newTotal) {
                                  _totalPages = newTotal;
                                }

                                // Update page via ValueNotifier (no setState → no PDFView rebuild)
                                if (_pageNotifier.value != newPage) {
                                  _pageNotifier.value = newPage;
                                }

                                // Show slider bubble briefly
                                if (!_showSliderBubble) {
                                  setState(() {
                                    _showSliderBubble = true;
                                  });
                                }

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

                                // Display practice button when in the last 3 pages
                                final isInLast3Pages = newTotal > 0 &&
                                    newPage >=
                                        (newTotal - 3).clamp(0, newTotal - 1);
                                if (isInLast3Pages != _showCompletionPanel) {
                                  setState(() {
                                    _showCompletionPanel = isInLast3Pages;
                                  });
                                }

                                // Track last-page state & mark note as completed
                                final onLast = newTotal > 0 &&
                                    newPage >= newTotal - 1;
                                if (onLast != _isOnLastPage) {
                                  _isOnLastPage = onLast;
                                }
                                if (onLast && !_hasPromptedCompletion) {
                                  _triggerCompletion();
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
                            // ── Bottom Completion Panel ──────────────────────
                            Positioned(
                              left: 0,
                              right: 0,
                              bottom: 0,
                              child: _buildCompletionPanel(),
                            ),
                          ],
                        );
                      },
                    ),
    );
  }
}
