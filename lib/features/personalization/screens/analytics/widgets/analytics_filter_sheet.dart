import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matricmate/features/personalization/controllers/analytics_controller.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

class AnalyticsFilterSheet extends StatefulWidget {
  const AnalyticsFilterSheet({super.key, required this.controller});
  final AnalyticsController controller;

  @override
  State<AnalyticsFilterSheet> createState() => _AnalyticsFilterSheetState();
}

class _AnalyticsFilterSheetState extends State<AnalyticsFilterSheet> {
  late String _subject;
  late String _testType;
  late TimedFilter _timed;
  late ScoreFilter _score;

  @override
  void initState() {
    super.initState();
    final c = widget.controller;
    _subject = c.selectedSubject.value;
    _testType = c.selectedTestType.value;
    _timed = c.selectedTimed.value;
    _score = c.selectedScore.value;
  }

  bool get _isFiltered {
    return _subject != 'All Subjects' ||
        (_testType != 'All Types' && _testType != 'All Categories') ||
        _timed != TimedFilter.all ||
        _score != ScoreFilter.all;
  }

  void _reset() => setState(() {
    _subject = 'All Subjects';
    _testType = 'All Categories';
    _timed = TimedFilter.all;
    _score = ScoreFilter.all;
  });

  void _apply() {
    widget.controller.applyFilters(
      subject: _subject,
      testType: _testType,
      timed: _timed,
      score: _score,
    );
    Get.back();
  }

  @override
  Widget build(BuildContext context) {
    final dark = AppHelperFunctions.isDark(context);

    final subjects = [
      'All Subjects',
      ...widget.controller.availableSubjects.where((s) => s != 'All Subjects'),
    ];

    const categories = [
      'All Categories',
      'Entrance Exam',
      'Model Exam',
      'Chapter Test',
      'Grade Exam',
    ];

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          decoration: BoxDecoration(
            color: dark ? AppColors.darkCard : AppColors.white,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(24),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Handle ────────────────────────────────────────────
              const SizedBox(height: 10),
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: dark ? AppColors.darkBorder : const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // ── Header Row ────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Filters',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: dark ? AppColors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    if (_isFiltered)
                      GestureDetector(
                        onTap: _reset,
                        child: const Text(
                          'Reset',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Divider(
                height: 1,
                color: dark ? AppColors.darkBorder : const Color(0xFFF1F5F9),
              ),

              // ── Content ───────────────────────────────────────────
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Subject
                      _SectionLabel(title: 'Subject', dark: dark),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: subjects.map((subj) {
                          return _FilterPill(
                            label: subj,
                            isSelected: _subject == subj,
                            onTap: () => setState(() => _subject = subj),
                            dark: dark,
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 18),

                      // 2. Category
                      _SectionLabel(title: 'Category', dark: dark),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: categories.map((cat) {
                          final isSel = _testType == cat ||
                              (_testType == 'All Types' &&
                                  cat == 'All Categories');
                          return _FilterPill(
                            label: cat,
                            isSelected: isSel,
                            onTap: () => setState(() => _testType = cat),
                            dark: dark,
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 18),

                      // 3. Mode
                      _SectionLabel(title: 'Mode', dark: dark),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _SegmentOption(
                            label: 'All',
                            isSelected: _timed == TimedFilter.all,
                            onTap: () =>
                                setState(() => _timed = TimedFilter.all),
                            dark: dark,
                          ),
                          const SizedBox(width: 8),
                          _SegmentOption(
                            label: 'Timed',
                            isSelected: _timed == TimedFilter.timedOnly,
                            onTap: () =>
                                setState(() => _timed = TimedFilter.timedOnly),
                            dark: dark,
                          ),
                          const SizedBox(width: 8),
                          _SegmentOption(
                            label: 'Practice',
                            isSelected: _timed == TimedFilter.untimeOnly,
                            onTap: () => setState(
                                () => _timed = TimedFilter.untimeOnly),
                            dark: dark,
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // 4. Score
                      _SectionLabel(title: 'Score', dark: dark),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _SegmentOption(
                            label: 'All',
                            isSelected: _score == ScoreFilter.all,
                            onTap: () =>
                                setState(() => _score = ScoreFilter.all),
                            dark: dark,
                          ),
                          const SizedBox(width: 8),
                          _SegmentOption(
                            label: '≥ 70%',
                            subtitle: 'Mastered',
                            isSelected: _score == ScoreFilter.good,
                            onTap: () =>
                                setState(() => _score = ScoreFilter.good),
                            dark: dark,
                          ),
                          const SizedBox(width: 8),
                          _SegmentOption(
                            label: '< 50%',
                            subtitle: 'Needs Work',
                            isSelected: _score == ScoreFilter.poor,
                            onTap: () =>
                                setState(() => _score = ScoreFilter.poor),
                            dark: dark,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // ── Apply Button Footer ───────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: _apply,
                    child: const Text(
                      'Apply Filters',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Section Label ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.title, required this.dark});
  final String title;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: dark ? AppColors.white : const Color(0xFF0F172A),
      ),
    );
  }
}

// ── Filter Pill ───────────────────────────────────────────────────────────────

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.dark,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7.5),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : (dark
                  ? Colors.white.withValues(alpha: 0.05)
                  : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (dark ? AppColors.darkBorder : const Color(0xFFE2E8F0)),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected
                ? Colors.white
                : (dark ? AppColors.white : const Color(0xFF334155)),
          ),
        ),
      ),
    );
  }
}

// ── Segment Option ────────────────────────────────────────────────────────────

class _SegmentOption extends StatelessWidget {
  const _SegmentOption({
    required this.label,
    this.subtitle,
    required this.isSelected,
    required this.onTap,
    required this.dark,
  });

  final String label;
  final String? subtitle;
  final bool isSelected;
  final VoidCallback onTap;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary
                : (dark
                    ? Colors.white.withValues(alpha: 0.05)
                    : const Color(0xFFF1F5F9)),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? AppColors.primary
                  : (dark ? AppColors.darkBorder : const Color(0xFFE2E8F0)),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? Colors.white
                      : (dark ? AppColors.white : const Color(0xFF334155)),
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? Colors.white70
                        : (dark ? AppColors.darkGrey : AppColors.textSecondary),
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

// ── Active Filter Row ─────────────────────────────────────────────────────────

class ActiveFilterRow extends StatelessWidget {
  const ActiveFilterRow({super.key, required this.controller});
  final AnalyticsController controller;

  @override
  Widget build(BuildContext context) {
    final chips = <_DismissChip>[];

    if (controller.selectedSubject.value != 'All Subjects') {
      chips.add(
        _DismissChip(
          label: controller.selectedSubject.value,
          onRemove: () => controller.applyFilters(subject: 'All Subjects'),
        ),
      );
    }
    if (controller.selectedTestType.value != 'All Types' &&
        controller.selectedTestType.value != 'All Categories') {
      chips.add(
        _DismissChip(
          label: controller.selectedTestType.value,
          onRemove: () => controller.applyFilters(testType: 'All Categories'),
        ),
      );
    }
    if (controller.selectedTimed.value != TimedFilter.all) {
      chips.add(
        _DismissChip(
          label: controller.selectedTimed.value == TimedFilter.timedOnly
              ? 'Timed'
              : 'Practice',
          onRemove: () => controller.applyFilters(timed: TimedFilter.all),
        ),
      );
    }
    if (controller.selectedScore.value != ScoreFilter.all) {
      chips.add(
        _DismissChip(
          label: controller.selectedScore.value == ScoreFilter.good
              ? '≥ 70%'
              : '< 50%',
          onRemove: () => controller.applyFilters(score: ScoreFilter.all),
        ),
      );
    }

    if (chips.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            ...chips.map(
              (c) =>
                  Padding(padding: const EdgeInsets.only(right: 6), child: c),
            ),
            GestureDetector(
              onTap: controller.resetFilters,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                child: Text(
                  'Clear all',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DismissChip extends StatelessWidget {
  const _DismissChip({required this.label, required this.onRemove});

  final String label;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final dark = AppHelperFunctions.isDark(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: dark ? 0.2 : 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11.5,
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(
              Icons.close_rounded,
              size: 13,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
