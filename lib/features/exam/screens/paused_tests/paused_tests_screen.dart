import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matricmate/common/widgets/appbar/appbar.dart';
import 'package:matricmate/features/exam/controllers/subjects_controller.dart';
import 'package:matricmate/features/exam/models/paused_test_info.dart';
import 'package:matricmate/features/exam/screens/ready/ready.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/constants/sizes.dart';

// ── Type colour palette (muted) ─────────────────────────────────────────────
const _typeColors = {
  'entrance': Color(0xFFE9A94A), // amber/gold
  'model':    Color(0xFFE9A94A), // amber/gold
  'chapter':  Color(0xFFE9A94A), // amber/gold
  'grade':    Color(0xFFE9A94A), // amber/gold
};

Color _colorFor(String type) =>
    _typeColors[type] ?? const Color(0xFF636E72);

// ── Screen ────────────────────────────────────────────────────────────────────

class PausedTestsScreen extends StatefulWidget {
  const PausedTestsScreen({super.key});

  @override
  State<PausedTestsScreen> createState() => _PausedTestsScreenState();
}

class _PausedTestsScreenState extends State<PausedTestsScreen> {
  SubjectsController get ctrl => SubjectsController.instance;

  List<String>? get _filterTypes {
    final args = Get.arguments;
    if (args is Map && args.containsKey('types')) {
      return List<String>.from(args['types'] as List);
    }
    return null;
  }

  String get _title {
    final types = _filterTypes;
    if (types == null) return 'In Progress';
    if (types.contains('entrance') && types.contains('model')) {
      return 'Entrance & Model';
    }
    return 'In Progress';
  }

  @override
  void initState() {
    super.initState();
    ctrl.loadPausedTests();
  }

  @override
  Widget build(BuildContext context) {
    final filterTypes = _filterTypes;
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: Appbar(
        showBackArrow: true,
        title: Text(
          _title,
          style: Theme.of(context)
              .textTheme
              .headlineSmall!
              .copyWith(color: AppColors.white, fontWeight: FontWeight.w700),
        ),
      ),
      body: Obx(() {
        final all = ctrl.pausedTests;
        final tests = filterTypes == null
            ? all
            : all.where((t) => filterTypes.contains(t.testType)).toList();

        if (tests.isEmpty) {
          return _EmptyState(dark: dark);
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(
            AppSizes.defaultSpace,
            AppSizes.defaultSpace,
            AppSizes.defaultSpace,
            AppSizes.defaultSpace * 3,
          ),
          itemCount: tests.length + 1, // +1 for header
          itemBuilder: (_, i) {
            if (i == 0) return _Header(count: tests.length, dark: dark);
            return Padding(
              padding: const EdgeInsets.only(top: AppSizes.spaceBtwItems),
              child: _PausedTestCard(info: tests[i - 1], dark: dark),
            );
          },
        );
      }),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({required this.count, required this.dark});
  final int count;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.pending_actions_rounded,
                  size: 14,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 5),
                Text(
                  '$count test${count == 1 ? '' : 's'} in progress',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Card ──────────────────────────────────────────────────────────────────────

class _PausedTestCard extends StatelessWidget {
  const _PausedTestCard({required this.info, required this.dark});
  final PausedTestInfo info;
  final bool dark;

  String _typeLabel(String t) {
    switch (t) {
      case 'entrance':
        return 'Entrance';
      case 'model':
        return 'Model';
      case 'chapter':
        return 'Chapter';
      case 'grade':
        return 'Grade';
      default:
        return t.isEmpty ? 'Test' : t;
    }
  }

  @override
  Widget build(BuildContext context) {
    final draft = info.result;
    final total = draft.testQuestions.length;
    final answered = draft.selectedAnswers.length;
    final progress = total > 0 ? answered / total : 0.0;
    final pct = (progress * 100).round();
    final accent = _colorFor(info.testType);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => Get.dialog(
          ReadyDialog(
            qnCount: total,
            time: info.testTime,
            testId: draft.testId,
            id: -1,
            draft: draft,
            examTitle:
                info.testType == 'entrance' ? info.testTitle : null,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: dark ? AppColors.darkCard : AppColors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: dark ? 0.15 : 0.06),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
            border: Border(
              left: BorderSide(color: accent.withValues(alpha: 0.55), width: 2.5),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Circular progress ring ───────────────────────────
                _CircularProgress(progress: progress, pct: pct, color: accent),
                const SizedBox(width: 14),

                // ── Info column ──────────────────────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Type badge + subject
                      Row(
                        children: [
                          _TypeBadge(label: _typeLabel(info.testType), color: accent),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              info.subjectName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),

                      // Title
                      Text(
                        info.testTitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: dark ? AppColors.white : AppColors.textPrimary,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Progress bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: progress.clamp(0.0, 1.0),
                          minHeight: 4,
                          backgroundColor: accent.withValues(alpha: 0.08),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            accent.withValues(alpha: 0.65),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Progress text + resume
                      Row(
                        children: [
                          Text(
                            '$answered / $total answered',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const Spacer(),
                          // Resume chip
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.play_arrow_rounded,
                                  size: 12,
                                  color: accent.withValues(alpha: 0.80),
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  'Resume',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: accent.withValues(alpha: 0.80),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Circular progress ring ────────────────────────────────────────────────────

class _CircularProgress extends StatelessWidget {
  const _CircularProgress({
    required this.progress,
    required this.pct,
    required this.color,
  });
  final double progress;
  final int pct;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 52,
      height: 52,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: const Size(52, 52),
            painter: _RingPainter(progress: progress, color: color),
          ),
          Text(
            '$pct%',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.progress, required this.color});
  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final radius = (size.width - 6) / 2;
    const strokeW = 4.5;

    // Track
    canvas.drawCircle(
      Offset(cx, cy),
      radius,
      Paint()
        ..color = color.withValues(alpha: 0.08)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeW,
    );

    // Arc
    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: radius),
        -math.pi / 2,
        2 * math.pi * progress.clamp(0.0, 1.0),
        false,
        Paint()
          ..color = color.withValues(alpha: 0.70)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeW
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.color != color;
}

// ── Type badge ────────────────────────────────────────────────────────────────

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color.withValues(alpha: 0.80),
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.dark});
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_outline_rounded,
              size: 40,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'All caught up!',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: dark ? AppColors.white : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'No tests in progress right now.',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
