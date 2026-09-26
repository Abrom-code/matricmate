import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:matricmate/features/personalization/controllers/analytics_controller.dart';
import 'package:matricmate/routes/app_routes.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

class WeaknessActionPlanSection extends StatelessWidget {
  const WeaknessActionPlanSection({super.key, required this.controller});
  final AnalyticsController controller;

  @override
  Widget build(BuildContext context) {
    final dark = AppHelperFunctions.isDark(context);

    return Obx(() {
      final weakSubjects = controller.weakestAreas;
      final strongSubjects = controller.strongestAreas;
      final weakChapters = controller.weakestChapters;
      final recs = controller.recommendations;
      final totalTests = controller.testsCompleted.value;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Executive Diagnostic Summary Banner ───────────────────────────
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: (weakSubjects.isNotEmpty || totalTests == 0)
                  ? const Color(0xFFEF4444).withValues(alpha: dark ? 0.12 : 0.05)
                  : const Color(0xFF10B981).withValues(alpha: dark ? 0.12 : 0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: (weakSubjects.isNotEmpty || totalTests == 0)
                    ? const Color(0xFFEF4444).withValues(alpha: dark ? 0.35 : 0.20)
                    : const Color(0xFF10B981).withValues(alpha: dark ? 0.35 : 0.20),
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
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: (weakSubjects.isNotEmpty || totalTests == 0)
                        ? const Color(0xFFEF4444).withValues(alpha: dark ? 0.25 : 0.15)
                        : const Color(0xFF10B981).withValues(alpha: dark ? 0.25 : 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Icon(
                      weakSubjects.isNotEmpty
                          ? Iconsax.radar_copy
                          : Icons.verified_rounded,
                      color: weakSubjects.isNotEmpty
                          ? const Color(0xFFEF4444)
                          : const Color(0xFF10B981),
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        weakSubjects.isNotEmpty
                            ? '${weakSubjects.length} Focus Areas Identified'
                            : (totalTests == 0
                                ? 'Diagnostic Awaiting First Test'
                                : 'All Practiced Subjects On Target'),
                        style: TextStyle(
                          color: weakSubjects.isNotEmpty
                              ? const Color(0xFFEF4444)
                              : (totalTests == 0
                                  ? AppColors.primary
                                  : const Color(0xFF10B981)),
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        weakSubjects.isNotEmpty
                            ? 'Targeting below 70% threshold. Practice below chapters to raise your rank.'
                            : (totalTests == 0
                                ? 'Take your first test to reveal your personalized strengths and weaknesses.'
                                : 'Mastery maintained above 70%. Keep reinforcing with model exams!'),
                        style: TextStyle(
                          color: dark
                              ? AppColors.darkGrey
                              : AppColors.textSecondary,
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // ── Strengths vs Weaknesses Comparison Cards ──────────────────────
          if (strongSubjects.isNotEmpty && weakSubjects.isNotEmpty) ...[
            Row(
              children: [
                Expanded(
                  child: _StrengthWeaknessCard(
                    isStrength: true,
                    title: 'Top Strength',
                    subject: strongSubjects.first.name,
                    score: strongSubjects.first.avgScore,
                    dark: dark,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StrengthWeaknessCard(
                    isStrength: false,
                    title: 'Needs Focus',
                    subject: weakSubjects.first.name,
                    score: weakSubjects.first.avgScore,
                    dark: dark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
          ],

          // ── Priority Subjects Deficit ─────────────────────────────────────
          if (weakSubjects.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: dark ? AppColors.darkCard : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: dark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
                  width: 1.2,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Subject Score Deficits (Target 75%)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...weakSubjects.map((sub) {
                    final gap = (75.0 - sub.avgScore).clamp(0.0, 100.0);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                sub.name,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: dark ? AppColors.white : const Color(0xFF0F172A),
                                ),
                              ),
                              Text(
                                '${sub.avgScore.toStringAsFixed(0)}% (Gap: -${gap.toStringAsFixed(0)}%)',
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFEF4444),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: (sub.avgScore / 100).clamp(0.0, 1.0),
                              minHeight: 7,
                              backgroundColor: dark
                                  ? Colors.white.withValues(alpha: 0.08)
                                  : const Color(0xFFE2E8F0),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Color(0xFFEF4444),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],

          // ── Critical Chapters Needing Revision ────────────────────────────
          if (weakChapters.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: dark ? AppColors.darkCard : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: dark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
                  width: 1.2,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Weakest Practiced Chapters',
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${weakChapters.length} Chapters',
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFEF4444),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...weakChapters.map((ch) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: dark
                            ? Colors.white.withValues(alpha: 0.03)
                            : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: dark
                              ? AppColors.darkBorder
                              : const Color(0xFFE2E8F0),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444).withValues(
                                alpha: dark ? 0.25 : 0.12,
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${ch.avgScore.toStringAsFixed(0)}%',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFFEF4444),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  ch.chapterTitle,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: dark
                                        ? AppColors.white
                                        : const Color(0xFF0F172A),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  '${ch.subjectName} • Grade ${ch.grade} • Ch ${ch.chapterNumber}'
                                  '${ch.hasNoteCompleted ? " • Note Read ✓" : " • Note Unread"}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: ch.hasNoteCompleted
                                        ? const Color(0xFF10B981)
                                        : (dark
                                            ? AppColors.darkGrey
                                            : AppColors.textSecondary),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (ch.subjectId != null)
                            InkWell(
                              borderRadius: BorderRadius.circular(8),
                              onTap: () {
                                Get.toNamed(
                                  Routes.notes,
                                  arguments: {
                                    'id': ch.subjectId,
                                    'subject_id': ch.subjectId,
                                    'title': ch.subjectName,
                                    'subject': ch.subjectName,
                                  },
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  ch.hasNoteCompleted ? 'Review' : 'Read Note',
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],

          // ── Actionable Study Recommendations ──────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: dark ? AppColors.darkCard : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: dark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
                width: 1.2,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline_rounded,
                      color: Color(0xFFF59E0B),
                      size: 19,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Recommended Next Steps',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...recs.map((rec) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: dark
                          ? Colors.white.withValues(alpha: 0.03)
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: dark
                            ? AppColors.darkBorder
                            : const Color(0xFFE2E8F0),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Icon(
                            rec.type == RecommendationType.readNote
                                ? Iconsax.book_1_copy
                                : rec.type == RecommendationType.exploreNotes
                                    ? Iconsax.document_copy
                                    : Iconsax.task_copy,
                            size: 17,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                rec.title,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: dark
                                      ? AppColors.white
                                      : const Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                rec.subtitle,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: dark
                                      ? AppColors.darkGrey
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                          ),
                          onPressed: () {
                            if (rec.type == RecommendationType.readNote ||
                                rec.type == RecommendationType.exploreNotes) {
                              if (rec.subjectId != null) {
                                Get.toNamed(
                                  Routes.notes,
                                  arguments: {
                                    'id': rec.subjectId,
                                    'subject_id': rec.subjectId,
                                    'title': rec.subjectName,
                                    'subject': rec.subjectName,
                                  },
                                );
                              } else {
                                controller.switchTab(AnalyticsTab.notes);
                              }
                            } else {
                              // Switch to tests tab or navigate to subjects
                              controller.switchTab(AnalyticsTab.tests);
                            }
                          },
                          child: Text(
                            rec.badgeText,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      );
    });
  }
}

class _StrengthWeaknessCard extends StatelessWidget {
  const _StrengthWeaknessCard({
    required this.isStrength,
    required this.title,
    required this.subject,
    required this.score,
    required this.dark,
  });

  final bool isStrength;
  final String title;
  final String subject;
  final double score;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final color = isStrength ? const Color(0xFF10B981) : const Color(0xFFEF4444);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: dark ? 0.12 : 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: color.withValues(alpha: dark ? 0.3 : 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isStrength ? Icons.trending_up_rounded : Icons.priority_high_rounded,
                size: 14,
                color: color,
              ),
              const SizedBox(width: 4),
              Text(
                title.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: color,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            subject,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
              color: dark ? AppColors.white : const Color(0xFF0F172A),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            '${score.toStringAsFixed(0)}% Avg Accuracy',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
