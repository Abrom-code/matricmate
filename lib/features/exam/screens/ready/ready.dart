import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:matricmate/features/exam/controllers/question_controller.dart';
import 'package:matricmate/features/exam/models/result_model.dart';
import 'package:matricmate/routes/app_routes.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

/// Full-screen Test Overview & Mode Selection Page.
class ReadyScreen extends StatefulWidget {
  const ReadyScreen({
    super.key,
    required this.qnCount,
    required this.time,
    required this.testId,
    required this.id,
    this.draft,
    this.examTitle,
    this.description,
    this.subjectName,
  });

  final int qnCount;
  final int time;
  final int testId;
  final int id;

  /// Non-null when the user has an in-progress attempt to resume.
  final ResultModel? draft;

  /// Test title.
  final String? examTitle;

  /// Description or source info for the test.
  final String? description;

  /// Subject name (e.g. Physics, Biology).
  final String? subjectName;

  factory ReadyScreen.fromArgs(Map<String, dynamic> args) {
    return ReadyScreen(
      qnCount: args['qnCount'] ?? args['qn_count'] ?? 0,
      time: args['time'] ?? 0,
      testId: args['testId'] ?? args['test_id'] ?? 0,
      id: args['id'] ?? 0,
      draft: args['draft'] as ResultModel?,
      examTitle: args['examTitle'] ?? args['exam_title'] as String?,
      description: args['description'] as String?,
      subjectName: args['subjectName'] ?? args['subject_name'] as String?,
    );
  }

  @override
  State<ReadyScreen> createState() => _ReadyScreenState();
}

class _ReadyScreenState extends State<ReadyScreen> {
  late bool _isExamMode;

  @override
  void initState() {
    super.initState();
    // If draft exists, retain the mode it had; otherwise default to Practice Mode
    if (widget.draft != null) {
      _isExamMode = widget.draft!.checkedQuestions.isEmpty;
    } else {
      _isExamMode = false;
    }
  }

  void _launch({
    required bool examMode,
    bool isTimed = false,
    bool resume = false,
  }) {
    Get.delete<QuestionController>(force: true);
    // Replace ReadyScreen on the navigation stack so exiting or completing the
    // test directly returns to the tests list.
    Get.offNamed(
      Routes.questions,
      arguments: {
        'test_id': widget.testId,
        'is_timed': examMode || isTimed,
        'is_exam_mode': examMode,
        'time': widget.time,
        'id': widget.id,
        if (resume && widget.draft != null) 'draft': widget.draft,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final dark = AppHelperFunctions.isDark(context);
    final hasDraft = widget.draft != null;
    final answered = widget.draft?.selectedAnswers.length ?? 0;
    final hasDescription =
        widget.description != null && widget.description!.trim().isNotEmpty;
    final title = widget.examTitle?.trim().isNotEmpty == true
        ? widget.examTitle!.trim()
        : 'Entrance Exam Test';

    final borderColor = dark ? AppColors.darkBorder : AppColors.borderPrimary;
    final cardBg = dark ? AppColors.darkSurface : AppColors.white;

    return Scaffold(
      backgroundColor: dark ? AppColors.dark : AppColors.light,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Get.back(),
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
            color: dark ? AppColors.white : AppColors.textPrimary,
          ),
          tooltip: 'Back',
        ),
        title: Text(
          'Test Overview',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: dark ? AppColors.white : AppColors.textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── Scrollable Content Area ──────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── 1. Hero Test Title ────────────────────────────
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                        height: 1.3,
                        color: dark ? AppColors.white : const Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // ── 2. Quick Glance Stats Bar ─────────────────────
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: borderColor),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: dark ? 0.2 : 0.03,
                            ),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _StatItem(
                            icon: Iconsax.message_question_copy,
                            iconColor: AppColors.primary,
                            value: '${widget.qnCount}',
                            label: 'Questions',
                            dark: dark,
                          ),
                          _verticalDivider(borderColor),
                          _StatItem(
                            icon: Iconsax.timer_1_copy,
                            iconColor: Colors.blue,
                            value: widget.time > 0
                                ? '${widget.time} Min'
                                : 'Untimed',
                            label: 'Duration',
                            dark: dark,
                          ),
                          _verticalDivider(borderColor),
                          _StatItem(
                            icon: hasDraft
                                ? Iconsax.play_circle_copy
                                : Iconsax.document_text_1_copy,
                            iconColor: hasDraft
                                ? AppColors.secondary
                                : Colors.teal,
                            value: hasDraft
                                ? '$answered / ${widget.qnCount}'
                                : 'MCQ',
                            label: hasDraft ? 'Answered' : 'Format',
                            dark: dark,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),

                    // ── 3. In-Progress Resume Card (if draft exists) ──
                    if (hasDraft) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.secondary.withValues(
                                alpha: dark ? 0.18 : 0.12,
                              ),
                              AppColors.secondary.withValues(
                                alpha: dark ? 0.08 : 0.04,
                              ),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppColors.secondary.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(7),
                                  decoration: BoxDecoration(
                                    color: AppColors.secondary.withValues(
                                      alpha: 0.2,
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.play_arrow_rounded,
                                    size: 18,
                                    color: AppColors.secondary,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                const Expanded(
                                  child: Text(
                                    'Paused Attempt In Progress',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.secondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Answered $answered of ${widget.qnCount} questions. '
                              'Resume below or choose a mode to restart.',
                              style: TextStyle(
                                fontSize: 12.5,
                                height: 1.45,
                                color: dark
                                    ? AppColors.white.withValues(alpha: 0.85)
                                    : const Color(0xFF475569),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 22),
                    ],

                    // ── 4. Mode Selection Cards ───────────────────────
                    const Text(
                      'CHOOSE TEST MODE',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Practice Mode Card
                    _ModeCard(
                      isSelected: !_isExamMode,
                      title: 'Practice Mode',
                      subtitle:
                          'No timer (for study). See the answer and explanation for each question as you go.',
                      icon: Iconsax.book_1_copy,
                      accentColor: AppColors.primary,
                      dark: dark,
                      onTap: () {
                        setState(() {
                          _isExamMode = false;
                        });
                      },
                    ),
                    const SizedBox(height: 12),

                    // Real Exam Mode Card
                    _ModeCard(
                      isSelected: _isExamMode,
                      title: 'Real Exam Mode',
                      subtitle: widget.time > 0
                          ? 'Includes a ${widget.time}-min timer. You only see the answers, and explanations when you finish.'
                          : 'Exam simulation. You only see the answers, and explanations when you finish.',
                      icon: Iconsax.timer_1_copy,
                      accentColor: Colors.blue,
                      dark: dark,
                      onTap: () {
                        setState(() {
                          _isExamMode = true;
                        });
                      },
                    ),
                    const SizedBox(height: 22),

                    // ── 5. Description / About This Test ──────────────
                    const Text(
                      'TEST INSTRUCTIONS & DETAILS',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: borderColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (hasDescription) ...[
                            Text(
                              widget.description!.trim(),
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.6,
                                color: dark
                                    ? AppColors.white.withValues(alpha: 0.9)
                                    : const Color(0xFF334155),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Divider(
                              height: 1,
                              color: borderColor.withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: 12),
                          ],
                          _InstructionBullet(
                            icon: Icons.check_circle_outline_rounded,
                            text:
                                'Each question has 4 choices with one correct answer.',
                            dark: dark,
                          ),
                          const SizedBox(height: 8),
                          _InstructionBullet(
                            icon: Icons.bookmark_border_rounded,
                            text:
                                'Bookmark tricky questions during the test for quick revision.',
                            dark: dark,
                          ),
                          const SizedBox(height: 8),
                          _InstructionBullet(
                            icon: Icons.pause_circle_outline_rounded,
                            text:
                                'Your answers are auto-saved. You can pause anytime and resume later.',
                            dark: dark,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // ── Sticky Bottom Action Bar ──────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              decoration: BoxDecoration(
                color: dark ? AppColors.darkCard : AppColors.white,
                border: Border(top: BorderSide(color: borderColor)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: dark ? 0.35 : 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: hasDraft
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Resume Primary Button
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: () {
                              final wasExam =
                                  widget.draft!.checkedQuestions.isEmpty;
                              final wasTimed =
                                  widget.draft!.remainingSeconds > 0;
                              _launch(
                                examMode: wasExam,
                                isTimed: wasTimed,
                                resume: true,
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.secondary,
                              foregroundColor: Colors.white,
                              side: const BorderSide(
                                color: AppColors.secondary,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                              ),
                            ),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.play_arrow_rounded,
                                    size: 22,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Resume from Question ${answered + 1}',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Start Fresh Secondary Option
                        SizedBox(
                          width: double.infinity,
                          height: 44,
                          child: OutlinedButton(
                            onPressed: () => _launch(
                              examMode: _isExamMode,
                              isTimed: _isExamMode,
                              resume: false,
                            ),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: borderColor),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                              ),
                            ),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                'Start Fresh (${_isExamMode ? 'Exam' : 'Practice'})',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: dark
                                      ? AppColors.white.withValues(alpha: 0.8)
                                      : AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  : SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () => _launch(
                          examMode: _isExamMode,
                          isTimed: _isExamMode,
                          resume: false,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isExamMode
                              ? Colors.blue
                              : AppColors.primary,
                          foregroundColor: Colors.white,
                          side: BorderSide(
                            color: _isExamMode
                                ? Colors.blue
                                : AppColors.primary,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 3,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _isExamMode
                                    ? 'Start in Exam Mode'
                                    : 'Start in Practice Mode',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward_rounded, size: 18),
                            ],
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

  Widget _verticalDivider(Color borderColor) {
    return Container(
      width: 1,
      height: 34,
      color: borderColor.withValues(alpha: 0.6),
    );
  }
}

// ── Stat Item Component ───────────────────────────────────────────────────────

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
    required this.dark,
  });

  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(height: 5),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: dark ? AppColors.white : const Color(0xFF1E293B),
            ),
          ),
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: dark ? AppColors.darkGrey : AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Interactive Mode Card ────────────────────────────────────────────────────

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.isSelected,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.dark,
    required this.onTap,
  });

  final bool isSelected;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final bool dark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor = isSelected
        ? accentColor
        : (dark ? AppColors.darkBorder : AppColors.borderPrimary);

    return Material(
      color: isSelected
          ? accentColor.withValues(alpha: dark ? 0.14 : 0.07)
          : (dark ? AppColors.darkSurface : AppColors.white),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor, width: 1.5),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Icon Circle
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? accentColor
                      : accentColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: isSelected ? Colors.white : accentColor,
                ),
              ),
              const SizedBox(width: 14),
              // Text Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      textAlign: TextAlign.start,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: dark ? AppColors.white : const Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      textAlign: TextAlign.start,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.35,
                        color: dark
                            ? AppColors.white.withValues(alpha: 0.6)
                            : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Bullet Point Helper ───────────────────────────────────────────────────────

class _InstructionBullet extends StatelessWidget {
  const _InstructionBullet({
    required this.icon,
    required this.text,
    required this.dark,
  });

  final IconData icon;
  final String text;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12.5,
              height: 1.4,
              color: dark
                  ? AppColors.white.withValues(alpha: 0.75)
                  : const Color(0xFF475569),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Backwards-Compatible Adapter (For any code invoking ReadyDialog) ──────────

class ReadyDialog extends StatelessWidget {
  const ReadyDialog({
    super.key,
    required this.qnCount,
    required this.time,
    required this.testId,
    required this.id,
    this.draft,
    this.examTitle,
    this.description,
  });

  final int qnCount, time, testId, id;
  final ResultModel? draft;
  final String? examTitle;
  final String? description;

  @override
  Widget build(BuildContext context) {
    return ReadyScreen(
      qnCount: qnCount,
      time: time,
      testId: testId,
      id: id,
      draft: draft,
      examTitle: examTitle,
      description: description,
    );
  }
}
