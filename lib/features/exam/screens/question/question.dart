import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:matricmate/common/widgets/appbar/appbar.dart';
import 'package:matricmate/common/widgets/loaders/circular_loading.dart';
import 'package:matricmate/features/exam/controllers/bookmark_controller.dart';
import 'package:matricmate/features/exam/controllers/question_controller.dart';
import 'package:matricmate/features/exam/screens/question/widgets/normal_questions_section.dart';
import 'package:matricmate/features/exam/screens/question/widgets/passage_container.dart';
import 'package:matricmate/features/exam/screens/question/widgets/passage_layout_ctrl.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/constants/sizes.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

class QuestionScreen extends StatefulWidget {
  const QuestionScreen({super.key});

  @override
  State<QuestionScreen> createState() => _QuestionScreenState();
}

class _QuestionScreenState extends State<QuestionScreen> {
  final ScrollController _pageScrollController = ScrollController();

  // ── Overlay FAB ────────────────────────────────────────────────────────────
  OverlayEntry? _fabEntry;
  Offset? _fabOffset; // null = default bottom-right

  void _insertFab() {
    _fabEntry = OverlayEntry(builder: (_) => _OverlayFab(state: this));
    // Schedule insertion after the first frame so Overlay is ready.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Overlay.of(context).insert(_fabEntry!);
    });
  }

  void _removeFab() {
    _fabEntry?.remove();
    _fabEntry = null;
  }

  void _updateFabOffset(Offset o) {
    _fabOffset = o;
    _fabEntry?.markNeedsBuild();
  }

  @override
  void initState() {
    super.initState();
    _insertFab();
  }

  @override
  void dispose() {
    _removeFab();
    _pageScrollController.dispose();
    super.dispose();
  }

  void _showQuestionNavigator(BuildContext context, QuestionController ctrl) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _QuestionNavigatorSheet(controller: ctrl),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<QuestionController>();
    final bookmarkController = Get.find<BookmarkController>();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        AppHelperFunctions.showAppDialog(
          context,
          'Want to Exit?',
          'Your progress will be saved.',
          () {
            Navigator.pop(context);
            Navigator.pop(context);
          },
        );
      },
      child: Obx(() {
        final bool hasData = controller.testQuestions.isNotEmpty;
        final currentQ = hasData
            ? controller.testQuestions[controller.currentIndex.value]
            : null;

        // Keep FAB visible only when there are questions to navigate
        if (hasData) {
          _fabEntry ??= OverlayEntry(builder: (_) => _OverlayFab(state: this));
        }

        return Scaffold(
          appBar: Appbar(
            leadingIcon: Icons.close,
            leadingIconColor: AppColors.error,
            leadingOnPressed: () => AppHelperFunctions.showAppDialog(
              context,
              'Want to Exit?',
              'Your progress will not be saved.',
              () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
            ),

            title: Builder(
              builder: (context) {
                final hasPassage =
                    currentQ != null && currentQ.passageId != null;

                final sectionTitle =
                    (currentQ != null &&
                        currentQ.sectionTitle != null &&
                        currentQ.sectionTitle!.trim().isNotEmpty)
                    ? currentQ.sectionTitle!.trim()
                    : null;

                final timerText = controller.isTimed
                    ? controller.formattedTime(
                        controller.remainingSeconds.value,
                      )
                    : '';

                final counterText = hasData
                    ? '${controller.currentIndex.value + 1} of '
                          '${controller.testQuestions.length}'
                    : 'Loading...';

                if (hasPassage)
                  return PassageLayoutCtrl(controller: controller);

                final Color timerColor = controller.remainingSeconds.value < 300
                    ? Colors.amber
                    : AppColors.primary;

                if (sectionTitle == null) {
                  return Text(
                    controller.isTimed
                        ? '$counterText ($timerText)'
                        : counterText,
                    style: Theme.of(context).textTheme.titleMedium!.copyWith(
                      color:
                          controller.isTimed &&
                              controller.remainingSeconds.value < 300
                          ? Colors.amber
                          : AppColors.primary,
                    ),
                  );
                }

                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        sectionTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium!
                            .copyWith(color: AppColors.primary),
                      ),
                    ),
                    if (controller.isTimed) ...[
                      const SizedBox(width: AppSizes.xs),
                      Obx(
                        () => Text(
                          '(${controller.formattedTime(controller.remainingSeconds.value)})',
                          style: Theme.of(context).textTheme.labelMedium!
                              .copyWith(
                                color: timerColor,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
            centerTitle: true,
            actions: [
              if (currentQ != null)
                Obx(() {
                  final isSaved = controller.isBookmarked(currentQ.id);
                  return IconButton(
                    onPressed: isSaved
                        ? () =>
                              bookmarkController.removeFromBookmark(currentQ.id)
                        : () => bookmarkController.addToBookmark(currentQ.id),
                    icon: Icon(
                      isSaved
                          ? Iconsax.archive_minus
                          : Iconsax.archive_add_copy,
                      color: AppColors.primary,
                    ),
                  );
                }),
            ],
            backgroundColor: Colors.transparent,
          ),

          body: (controller.isLoading.value || controller.isPassageLoading.value)
              ? const AppCircularLoading()
              : SingleChildScrollView(
                  controller: _pageScrollController,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (currentQ?.passageId != null)
                        PassageContainer(controller: controller),
                      if (currentQ != null)
                        QuesitonSection(question: currentQ),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
        );
      }),
    );
  }
}

// ── Question Navigator Bottom Sheet ─────────────────────────────────────────

class _QuestionNavigatorSheet extends StatelessWidget {
  const _QuestionNavigatorSheet({required this.controller});
  final QuestionController controller;

  @override
  Widget build(BuildContext context) {
    final dark = AppHelperFunctions.isDark(context);
    final sheetBg = dark ? AppColors.darkCard : AppColors.white;

    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.35,
      maxChildSize: 0.90,
      expand: false,
      builder: (_, scrollCtrl) => Container(
        decoration: BoxDecoration(
          color: sheetBg,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppSizes.borderRadiusLg * 2),
          ),
        ),
        child: Column(
          children: [
            // drag handle
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSizes.sm),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.darkGrey.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // header
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.defaultSpace,
                vertical: AppSizes.xs,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Questions',
                    style: Theme.of(context).textTheme.titleMedium!.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      const _LegendDot(color: AppColors.success, label: 'Done'),
                      const SizedBox(width: AppSizes.sm),
                      const _LegendDot(color: Colors.amber, label: 'Skipped'),
                      const SizedBox(width: AppSizes.sm),
                      _LegendDot(
                        color: AppColors.darkGrey.withValues(alpha: 0.35),
                        label: 'Not done',
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            Expanded(
              child: Obx(() {
                final questions = controller.testQuestions;

                // Build ordered list of sections, preserving question order.
                // Key = section label (title or null-group key).
                // Value = list of (globalIndex, question) pairs.
                final bool hasSections = questions.any(
                  (q) =>
                      q.sectionTitle != null &&
                      q.sectionTitle!.trim().isNotEmpty,
                );

                if (!hasSections) {
                  // ── Plain grid (no sections) ──────────────────────────────
                  return GridView.builder(
                    controller: scrollCtrl,
                    padding: const EdgeInsets.all(AppSizes.defaultSpace),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 6,
                          crossAxisSpacing: AppSizes.xs,
                          mainAxisSpacing: AppSizes.xs,
                        ),
                    itemCount: questions.length,
                    itemBuilder: (_, i) => _QuestionTile(
                      index: i,
                      controller: controller,
                      dark: dark,
                      context: context,
                    ),
                  );
                }

                // ── Sectioned list ────────────────────────────────────────
                // Group into ordered sections, preserving encounter order.
                final sections = <String, List<int>>{};
                for (int i = 0; i < questions.length; i++) {
                  final label =
                      (questions[i].sectionTitle?.trim().isNotEmpty == true)
                      ? questions[i].sectionTitle!.trim()
                      : '—';
                  sections.putIfAbsent(label, () => []).add(i);
                }

                // Flatten into a scroll-list of header + grid rows
                return CustomScrollView(
                  controller: scrollCtrl,
                  slivers: [
                    for (final entry in sections.entries) ...[
                      // Section header
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AppSizes.defaultSpace,
                            AppSizes.spaceBtwItems,
                            AppSizes.defaultSpace,
                            AppSizes.sm,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  entry.key,
                                  style: Theme.of(context).textTheme.titleSmall!
                                      .copyWith(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                              ),
                              Text(
                                '${entry.value.length} questions',
                                style: Theme.of(context).textTheme.labelSmall!
                                    .copyWith(color: AppColors.darkGrey),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Grid of tiles for this section
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.defaultSpace,
                        ),
                        sliver: SliverGrid(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 6,
                                crossAxisSpacing: AppSizes.xs,
                                mainAxisSpacing: AppSizes.xs,
                              ),
                          delegate: SliverChildBuilderDelegate(
                            (_, j) => _QuestionTile(
                              index: entry.value[j],
                              controller: controller,
                              dark: dark,
                              context: context,
                            ),
                            childCount: entry.value.length,
                          ),
                        ),
                      ),
                    ],
                    const SliverToBoxAdapter(
                      child: SizedBox(height: AppSizes.defaultSpace),
                    ),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Single question number tile ───────────────────────────────────────────────

class _QuestionTile extends StatelessWidget {
  const _QuestionTile({
    required this.index,
    required this.controller,
    required this.dark,
    required this.context,
  });

  final int index;
  final QuestionController controller;
  final bool dark;
  final BuildContext context;

  @override
  Widget build(BuildContext _) {
    final q = controller.testQuestions[index];
    final isCurrent = controller.currentIndex.value == index;
    final isSkipped = controller.isSkipped(q.id);
    final isDone = controller.isExamMode
        ? controller.selectedAnswers.containsKey(q.id)
        : controller.isAnswerChecked(q.id);

    final Color bg;
    if (isDone) {
      bg = AppColors.success;
    } else if (isSkipped) {
      bg = Colors.amber;
    } else {
      bg = dark ? AppColors.darkSurface : AppColors.grey;
    }

    return GestureDetector(
      onTap: () {
        controller.jumpToQuestion(index);
        Navigator.pop(context);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
          border: isCurrent
              ? Border.all(color: AppColors.primary, width: 2.5)
              : null,
          boxShadow: isCurrent
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.4),
                    blurRadius: 6,
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            '${index + 1}',
            style: TextStyle(
              color: isDone || isSkipped
                  ? AppColors.white
                  : dark
                  ? AppColors.white.withValues(alpha: 0.8)
                  : AppColors.darkerGrey,
              fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 3),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.labelSmall!.copyWith(color: AppColors.darkGrey),
        ),
      ],
    );
  }
}

// ── Overlay FAB ───────────────────────────────────────────────────────────────
//
// Renders the draggable FAB in the Flutter Overlay so it floats above the
// entire screen — including the AppBar and system UI areas.
//
// • Default position: bottom-right corner (matches original floatingActionButton).
// • Drag freely across the whole screen.
// • Clamped to screen bounds so it never goes fully off-screen.
// • Uses Listener (raw pointer events) so dragging never loses to the
//   scroll view's gesture arena.

class _OverlayFab extends StatelessWidget {
  const _OverlayFab({required this.state});

  final _QuestionScreenState state;

  static const double _size   = 56;
  static const double _margin = 16;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<QuestionController>();
    final screen     = MediaQuery.of(context).size;
    final padding    = MediaQuery.of(context).padding;

    // Usable area: full screen minus system bars
    final maxX = screen.width  - _size - _margin;
    final maxY = screen.height - _size - _margin - padding.bottom;
    final minX = _margin;
    final minY = _margin + padding.top;

    // Use stored offset or default to bottom-right
    final pos = state._fabOffset ??
        Offset(maxX, maxY);

    return Positioned(
      left: pos.dx,
      top:  pos.dy,
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerMove: (event) {
          final next = Offset(
            (pos.dx + event.delta.dx).clamp(minX, maxX),
            (pos.dy + event.delta.dy).clamp(minY, maxY),
          );
          state._updateFabOffset(next);
        },
        child: _ProgressFab(
          controller: controller,
          onPressed: () =>
              state._showQuestionNavigator(context, controller),
        ),
      ),
    );
  }
}

// ── Progress FAB ─────────────────────────────────────────────────────────────

class _ProgressFab extends StatelessWidget {
  const _ProgressFab({required this.controller, required this.onPressed});

  final QuestionController controller;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final total = controller.testQuestions.length;
      final done = controller.isExamMode
          ? controller.selectedAnswers.length
          : controller.isChecked.values.where((v) => v).length;
      final progress = total == 0 ? 0.0 : done / total;

      return GestureDetector(
        onTap: onPressed,
        child: SizedBox(
          width: 56,
          height: 56,
          child: CustomPaint(
            painter: _ProgressRingPainter(
              progress: progress,
              ringColor: AppColors.primary,
              trackColor: AppColors.primary.withValues(alpha: 0.18),
            ),
            child: Container(
              margin: const EdgeInsets.all(5),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.grid_view_rounded,
                color: AppColors.white,
                size: 22,
              ),
            ),
          ),
        ),
      );
    });
  }
}

class _ProgressRingPainter extends CustomPainter {
  const _ProgressRingPainter({
    required this.progress,
    required this.ringColor,
    required this.trackColor,
  });

  final double progress;
  final Color ringColor;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 3.5;
    final rect = Rect.fromLTWH(
      strokeWidth / 2,
      strokeWidth / 2,
      size.width - strokeWidth,
      size.height - strokeWidth,
    );

    // background track
    canvas.drawArc(
      rect,
      -1.5708, // -90° (start at top)
      6.2832, // full circle
      false,
      Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );

    // progress arc
    if (progress > 0) {
      canvas.drawArc(
        rect,
        -1.5708,
        6.2832 * progress,
        false,
        Paint()
          ..color = ringColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_ProgressRingPainter old) => old.progress != progress;
}
