import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:matricmate/common/widgets/appbar/modern_appbar.dart';
import 'package:matricmate/common/widgets/loaders/circular_loading.dart';
import 'package:matricmate/features/exam/controllers/pilot_exam_controller.dart';
import 'package:matricmate/features/exam/models/pilot_exam_model.dart';
import 'package:matricmate/features/personalization/controllers/user_controller.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

class PilotExamSubjectsScreen extends StatefulWidget {
  const PilotExamSubjectsScreen({super.key});

  @override
  State<PilotExamSubjectsScreen> createState() => _PilotExamSubjectsScreenState();
}

class _PilotExamSubjectsScreenState extends State<PilotExamSubjectsScreen> {
  PilotExamController get controller => PilotExamController.instance;

  @override
  Widget build(BuildContext context) {
    final dark = AppHelperFunctions.isDark(context);
    final user = UserController.instance.user.value;
    final stream = user.stream.isNotEmpty
        ? '${user.stream[0].toUpperCase()}${user.stream.substring(1)} Stream'
        : 'National Stream';

    return Scaffold(
      backgroundColor: dark ? AppColors.dark : const Color(0xFFF8FAFC),
      appBar: ModernAppbar(
        title: controller.selectedExam.value?.title ?? 'Pilot Exam',
        subtitle: '$stream • 6 Subjects Simulation',
        showBackArrow: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              tooltip: 'Refresh',
              onPressed: () => controller.loadSubjectsForSelectedExam(),
              icon: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Iconsax.refresh_copy,
                    size: 17,
                    color: AppColors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoadingSubjects.value) {
          return const AppCircularLoading(title: 'Loading exam subjects...');
        }

        final subjects = controller.examSubjects;
        final completedCount = controller.completedSubjectsCount;
        final grandTotal = controller.grandTotalScore;
        final compositePct = controller.compositePercentage;

        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: controller.loadSubjectsForSelectedExam,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              16,
              16,
              16,
              MediaQuery.paddingOf(context).bottom + 40,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Composite Scorecard Hero ───────────────────────────────
                _CompositeScorecardCard(
                  dark: dark,
                  completedCount: completedCount,
                  totalSubjects: subjects.length,
                  grandTotal: grandTotal,
                  compositePct: compositePct,
                ),

                const SizedBox(height: 22),

                // ── Section Title ──────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Exam Subjects',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: dark ? Colors.white : AppColors.textPrimary,
                        letterSpacing: -0.3,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3.5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(
                          alpha: dark ? 0.22 : 0.1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$completedCount/${subjects.length} Completed',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // ── 6 Subject Cards List ───────────────────────────────────
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: subjects.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final subject = subjects[index];
                    final isCompleted = controller.isSubjectCompleted(subject.testId);
                    final isInProgress = controller.isSubjectInProgress(subject.testId);
                    final score100 = controller.getSubjectScoreOutOf100(
                      subject.testId,
                      subject.questionCount,
                    );

                    return _SubjectExamTile(
                      dark: dark,
                      subject: subject,
                      isCompleted: isCompleted,
                      isInProgress: isInProgress,
                      scoreOutOf100: score100,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        controller.startSubjectExam(subject, user);
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

// ── Composite Scorecard Card ─────────────────────────────────────────────────

class _CompositeScorecardCard extends StatelessWidget {
  const _CompositeScorecardCard({
    required this.dark,
    required this.completedCount,
    required this.totalSubjects,
    required this.grandTotal,
    required this.compositePct,
  });

  final bool dark;
  final int completedCount;
  final int totalSubjects;
  final double grandTotal;
  final double compositePct;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: dark
              ? [
                  const Color(0xFF0F766E),
                  const Color(0xFF115E59),
                  const Color(0xFF042F2C),
                ]
              : [
                  const Color(0xFF0D9488),
                  const Color(0xFF0F766E),
                  const Color(0xFF134E4A),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0D9488).withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Circular percentage indicator
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 70,
                height: 70,
                child: CircularProgressIndicator(
                  value: completedCount > 0 ? (compositePct / 100.0).clamp(0.0, 1.0) : 0.0,
                  strokeWidth: 6.5,
                  strokeCap: StrokeCap.round,
                  backgroundColor: Colors.white.withValues(alpha: 0.15),
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF34D399)),
                ),
              ),
              Text(
                completedCount > 0
                    ? '${compositePct.toStringAsFixed(0)}%'
                    : '0%',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const SizedBox(width: 18),

          // Score details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Grand Total Score',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFFCCFBF1),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: grandTotal.toStringAsFixed(0),
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -1,
                        ),
                      ),
                      const TextSpan(
                        text: ' / 600',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF99F6E4),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '$completedCount of $totalSubjects subjects completed',
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFFE6FFFA),
                    fontWeight: FontWeight.w500,
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

// ── Subject Exam Tile ────────────────────────────────────────────────────────

class _SubjectExamTile extends StatelessWidget {
  const _SubjectExamTile({
    required this.dark,
    required this.subject,
    required this.isCompleted,
    required this.isInProgress,
    required this.scoreOutOf100,
    required this.onTap,
  });

  final bool dark;
  final PilotExamSubjectModel subject;
  final bool isCompleted;
  final bool isInProgress;
  final double scoreOutOf100;
  final VoidCallback onTap;

  IconData _getSubjectIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('math')) return Iconsax.math_copy;
    if (lower.contains('physic')) return Iconsax.radar_copy;
    if (lower.contains('chem')) return Iconsax.bubble_copy;
    if (lower.contains('bio')) return Iconsax.heart_copy;
    if (lower.contains('eng')) return Iconsax.language_square_copy;
    if (lower.contains('hist')) return Iconsax.book_copy;
    if (lower.contains('geo')) return Iconsax.global_copy;
    if (lower.contains('econ')) return Iconsax.chart_copy;
    return Iconsax.note_2_copy;
  }

  Color _getSubjectColor(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('math')) return const Color(0xFF2563EB);
    if (lower.contains('physic')) return const Color(0xFF7C3AED);
    if (lower.contains('chem')) return const Color(0xFF0D9488);
    if (lower.contains('bio')) return const Color(0xFF059669);
    if (lower.contains('eng')) return const Color(0xFFEA580C);
    if (lower.contains('hist')) return const Color(0xFFD97706);
    if (lower.contains('geo')) return const Color(0xFF0284C7);
    if (lower.contains('econ')) return const Color(0xFF4F46E5);
    return AppColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    final color = _getSubjectColor(subject.subjectName);
    final icon = _getSubjectIcon(subject.subjectName);

    return Container(
      decoration: BoxDecoration(
        color: dark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isCompleted
              ? const Color(0xFF10B981).withValues(alpha: dark ? 0.35 : 0.25)
              : (dark ? AppColors.darkBorder : const Color(0xFFE2E8F0)),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Subject Avatar
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: dark ? 0.22 : 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Icon(icon, color: color, size: 22),
                  ),
                ),
                const SizedBox(width: 14),

                // Name & Meta
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subject.subjectName,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: dark ? Colors.white : AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${subject.timeMinutes} mins • ${subject.questionCount} questions',
                        style: TextStyle(
                          fontSize: 12,
                          color: dark ? AppColors.darkGrey : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 10),

                // Score / Status Pill
                if (isCompleted) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: dark ? 0.22 : 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFF10B981).withValues(alpha: 0.35),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${scoreOutOf100.toStringAsFixed(0)} / 100',
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF10B981),
                          ),
                        ),
                        const Text(
                          'Completed ✓',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF10B981),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else if (isInProgress) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withValues(alpha: dark ? 0.22 : 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'Resume',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFF59E0B),
                      ),
                    ),
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      'Start',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
