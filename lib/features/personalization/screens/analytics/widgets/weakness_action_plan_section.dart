import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:matricmate/features/personalization/controllers/analytics_controller.dart';
import 'package:matricmate/routes/app_routes.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

class WeaknessActionPlanSection extends StatefulWidget {
  const WeaknessActionPlanSection({super.key, required this.controller});
  final AnalyticsController controller;

  @override
  State<WeaknessActionPlanSection> createState() =>
      _WeaknessActionPlanSectionState();
}

class _WeaknessActionPlanSectionState extends State<WeaknessActionPlanSection> {
  int _selectedFilter = 0; // 0 = Priority Focus, 1 = Strengths

  @override
  Widget build(BuildContext context) {
    final dark = AppHelperFunctions.isDark(context);

    return Obx(() {
      final weakSubjects = widget.controller.weakestAreas;
      final strongSubjects = widget.controller.strongestAreas;
      final weakChapters = widget.controller.weakestChapters;
      final recs = widget.controller.recommendations;
      final totalTests = widget.controller.testsCompleted.value;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── 1. Hero Diagnostic Header Card ────────────────────────────────
          _HeroDiagnosticCard(
            totalTests: totalTests,
            weakCount: weakSubjects.length,
            strongCount: strongSubjects.length,
            dark: dark,
          ),
          const SizedBox(height: 14),

          // ── 2. Perspective Toggle: Focus Areas vs Strengths ───────────────
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: dark ? AppColors.darkCard : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: dark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
                width: 1.2,
              ),
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
              children: [
                _SubTab(
                  icon: Iconsax.radar_copy,
                  title: 'Priority Focus',
                  badgeCount: weakSubjects.length,
                  isSelected: _selectedFilter == 0,
                  badgeColor: const Color(0xFFEF4444),
                  onTap: () => setState(() => _selectedFilter = 0),
                  dark: dark,
                ),
                _SubTab(
                  icon: Icons.verified_rounded,
                  title: 'Key Strengths',
                  badgeCount: strongSubjects.length,
                  isSelected: _selectedFilter == 1,
                  badgeColor: const Color(0xFF10B981),
                  onTap: () => setState(() => _selectedFilter = 1),
                  dark: dark,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // ── 3. Content: Focus Mode vs Strengths Mode ──────────────────────
          if (_selectedFilter == 0) ...[
            // ── Personalized Study Roadmap (1-2-3 Step Plan) ────────────────
            if (recs.isNotEmpty) ...[
              _StudyRoadmapCard(
                recs: recs,
                controller: widget.controller,
                dark: dark,
              ),
              const SizedBox(height: 14),
            ],

            // ── Subject Mastery Deficit List ─────────────────────────────────
            if (weakSubjects.isNotEmpty) ...[
              _SubjectDeficitList(
                weakSubjects: weakSubjects,
                controller: widget.controller,
                dark: dark,
              ),
              const SizedBox(height: 14),
            ],

            // ── Critical Chapters Needing Revision ────────────────────────────
            if (weakChapters.isNotEmpty) ...[
              _WeakChaptersCard(
                weakChapters: weakChapters,
                controller: widget.controller,
                dark: dark,
              ),
            ] else if (weakSubjects.isEmpty && totalTests > 0) ...[
              _AllGoodEmptyState(dark: dark),
            ],
          ] else ...[
            // ── Strengths Mode ──────────────────────────────────────────────
            _StrengthsList(
              strongSubjects: strongSubjects,
              controller: widget.controller,
              dark: dark,
            ),
          ],
        ],
      );
    });
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ── SUB-COMPONENTS ───────────────────────────────────────────────────────────
// ─────────────────────────────────────────────────────────────────────────────

class _HeroDiagnosticCard extends StatelessWidget {
  const _HeroDiagnosticCard({
    required this.totalTests,
    required this.weakCount,
    required this.strongCount,
    required this.dark,
  });

  final int totalTests;
  final int weakCount;
  final int strongCount;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final bool hasNeedsFocus = weakCount > 0;
    final bool isBrandNew = totalTests == 0;

    final Color accentColor = isBrandNew
        ? AppColors.primary
        : (hasNeedsFocus ? const Color(0xFFF59E0B) : const Color(0xFF10B981));

    String title;
    String subtitle;
    IconData icon;

    if (isBrandNew) {
      title = 'Diagnostic Ready';
      subtitle = 'Complete practice tests to unlock your personalized weakness diagnostic';
      icon = Icons.auto_awesome_rounded;
    } else if (hasNeedsFocus) {
      title = '$weakCount Priority ${weakCount == 1 ? "Subject" : "Subjects"} To Target';
      subtitle = 'Below 70% threshold. Follow the action plan below to boost your matric rank';
      icon = Iconsax.radar_copy;
    } else {
      title = 'High Proficiency Achieved';
      subtitle = 'All practiced subjects exceed the 70% threshold. Keep sharpening with tests';
      icon = Icons.verified_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: dark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: dark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? 0.25 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: dark ? 0.22 : 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Icon(icon, color: accentColor, size: 22),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                        color: dark ? AppColors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: dark
                            ? AppColors.darkGrey
                            : AppColors.textSecondary,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 2 Mini Metric Indicators
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withValues(alpha: dark ? 0.12 : 0.06),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFFEF4444).withValues(alpha: dark ? 0.25 : 0.15),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.arrow_downward_rounded, size: 14, color: Color(0xFFEF4444)),
                      const SizedBox(width: 5),
                      Text(
                        '$weakCount Below 70%',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFEF4444),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: dark ? 0.12 : 0.06),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFF10B981).withValues(alpha: dark ? 0.25 : 0.15),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.arrow_upward_rounded, size: 14, color: Color(0xFF10B981)),
                      const SizedBox(width: 5),
                      Text(
                        '$strongCount Proficient',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SubTab extends StatelessWidget {
  const _SubTab({
    required this.icon,
    required this.title,
    required this.isSelected,
    required this.badgeCount,
    required this.badgeColor,
    required this.onTap,
    required this.dark,
  });

  final IconData icon;
  final String title;
  final bool isSelected;
  final int badgeCount;
  final Color badgeColor;
  final VoidCallback onTap;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 15,
                color: isSelected
                    ? Colors.white
                    : (dark ? AppColors.darkGrey : AppColors.textSecondary),
              ),
              const SizedBox(width: 5),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected
                      ? Colors.white
                      : (dark ? AppColors.darkGrey : AppColors.textSecondary),
                ),
              ),
              if (badgeCount > 0 && !isSelected) ...[
                const SizedBox(width: 5),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '$badgeCount',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      color: badgeColor,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StudyRoadmapCard extends StatelessWidget {
  const _StudyRoadmapCard({
    required this.recs,
    required this.controller,
    required this.dark,
  });

  final List<StudyRecommendation> recs;
  final AnalyticsController controller;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: dark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: dark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.route_rounded,
                  color: Color(0xFFF59E0B),
                  size: 17,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Personalized Study Plan',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),
                    Text(
                      'Actionable steps ordered by potential matric rank impact',
                      style: TextStyle(
                        fontSize: 11,
                        color: dark ? AppColors.darkGrey : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          ...recs.asMap().entries.map((entry) {
            final int index = entry.key + 1;
            final StudyRecommendation rec = entry.value;

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
                  // Step Index Circle
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: dark ? 0.25 : 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '$index',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Title & Subtitle
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
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
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
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Button styled like notes read button
                  InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () {
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
                        controller.switchTab(AnalyticsTab.tests);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(
                          alpha: dark ? 0.2 : 0.08,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            rec.badgeText,
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(width: 3),
                          const Icon(
                            Icons.chevron_right_rounded,
                            size: 14,
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _SubjectDeficitList extends StatelessWidget {
  const _SubjectDeficitList({
    required this.weakSubjects,
    required this.controller,
    required this.dark,
  });

  final List<SubjectStat> weakSubjects;
  final AnalyticsController controller;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Container(
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
                'Focus Subjects & Target Gap',
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Goal: 75%',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFEF4444),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          ...weakSubjects.map((sub) {
            final gap = (75.0 - sub.avgScore).clamp(0.0, 100.0);

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: dark
                    ? Colors.white.withValues(alpha: 0.02)
                    : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: dark
                      ? AppColors.darkBorder
                      : const Color(0xFFE2E8F0),
                  width: 0.8,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Subject Avatar
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            sub.name.isNotEmpty ? sub.name[0] : 'S',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFFEF4444),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              sub.name,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: dark
                                    ? AppColors.white
                                    : const Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              '${sub.testsCount} tests practiced',
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

                      // Gap Pill
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '-${gap.toStringAsFixed(0)}% Gap',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFFEF4444),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Progress Bar & Percentage
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Current Accuracy',
                        style: TextStyle(
                          fontSize: 11,
                          color: dark ? AppColors.darkGrey : AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        '${sub.avgScore.toStringAsFixed(0)}%',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFEF4444),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: (sub.avgScore / 100).clamp(0.0, 1.0),
                      minHeight: 6,
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
    );
  }
}

class _WeakChaptersCard extends StatelessWidget {
  const _WeakChaptersCard({
    required this.weakChapters,
    required this.controller,
    required this.dark,
  });

  final List<WeakChapterStat> weakChapters;
  final AnalyticsController controller;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Container(
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
                'Critical Chapters Needing Revision',
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${weakChapters.length} Chapters',
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
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
                  // Score Badge
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(
                        alpha: dark ? 0.22 : 0.12,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        '${ch.avgScore.toStringAsFixed(0)}%',
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFFEF4444),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Chapter Details
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
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              '${ch.subjectName} • G${ch.grade}',
                              style: TextStyle(
                                fontSize: 11,
                                color: dark
                                    ? AppColors.darkGrey
                                    : AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: ch.hasNoteCompleted
                                    ? const Color(0xFF10B981).withValues(alpha: 0.15)
                                    : const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                ch.hasNoteCompleted ? 'Read ✓' : 'Note Unread',
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  color: ch.hasNoteCompleted
                                      ? const Color(0xFF10B981)
                                      : const Color(0xFF8B5CF6),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Open Note / Test Button
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
                          horizontal: 9,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(
                            alpha: dark ? 0.2 : 0.08,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              ch.hasNoteCompleted ? 'Review' : 'Read Note',
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 3),
                            const Icon(
                              Icons.chevron_right_rounded,
                              size: 13,
                              color: AppColors.primary,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _StrengthsList extends StatelessWidget {
  const _StrengthsList({
    required this.strongSubjects,
    required this.controller,
    required this.dark,
  });

  final List<SubjectStat> strongSubjects;
  final AnalyticsController controller;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    if (strongSubjects.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: dark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: dark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
            width: 1.2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              Icons.trending_up_rounded,
              size: 40,
              color: dark ? AppColors.darkGrey : AppColors.textSecondary,
            ),
            const SizedBox(height: 10),
            const Text(
              'No Strength Subjects Yet',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Score above 60% in practice tests to establish your mastered subjects.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: dark ? AppColors.darkGrey : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
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
                'Mastered Subjects',
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${strongSubjects.length} High Scoring',
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF10B981),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          ...strongSubjects.map((sub) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: dark
                    ? Colors.white.withValues(alpha: 0.02)
                    : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: dark
                      ? AppColors.darkBorder
                      : const Color(0xFFE2E8F0),
                  width: 0.8,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            sub.name.isNotEmpty ? sub.name[0] : 'S',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF10B981),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              sub.name,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: dark
                                    ? AppColors.white
                                    : const Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              '${sub.testsCount} tests practiced • High accuracy',
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
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${sub.avgScore.toStringAsFixed(0)}% Mastered',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF10B981),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: (sub.avgScore / 100).clamp(0.0, 1.0),
                      minHeight: 6,
                      backgroundColor: dark
                          ? Colors.white.withValues(alpha: 0.08)
                          : const Color(0xFFE2E8F0),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFF10B981),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _AllGoodEmptyState extends StatelessWidget {
  const _AllGoodEmptyState({required this.dark});
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF10B981).withValues(alpha: dark ? 0.12 : 0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFF10B981).withValues(alpha: dark ? 0.3 : 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.verified_rounded,
            size: 40,
            color: Color(0xFF10B981),
          ),
          const SizedBox(height: 10),
          const Text(
            'All Practiced Subjects On Target!',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'No urgent weaknesses detected. Continue with model exams to keep your top matric rank.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: dark ? AppColors.darkGrey : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
