import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
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

  int get _activeCount {
    int count = 0;
    if (_subject != 'All Subjects') count++;
    if (_testType != 'All Types' && _testType != 'All Categories') count++;
    if (_timed != TimedFilter.all) count++;
    if (_score != ScoreFilter.all) count++;
    return count;
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
    final activeCount = _activeCount;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.88,
          ),
          decoration: BoxDecoration(
            color: dark ? AppColors.darkCard : AppColors.white,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(28),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: dark ? 0.4 : 0.08),
                blurRadius: 24,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Drag Handle ──────────────────────────────────────────────
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 44,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: dark ? AppColors.darkBorder : const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // ── Header Row ──────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(
                          alpha: dark ? 0.22 : 0.10,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.tune_rounded,
                          size: 18,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Filter Insights',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.3,
                                  color: dark
                                      ? AppColors.white
                                      : const Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: activeCount > 0
                                      ? AppColors.primary.withValues(
                                          alpha: dark ? 0.25 : 0.12,
                                        )
                                      : (dark
                                          ? Colors.white.withValues(alpha: 0.06)
                                          : const Color(0xFFF1F5F9)),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  activeCount > 0
                                      ? '$activeCount active'
                                      : 'All included',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    color: activeCount > 0
                                        ? AppColors.primary
                                        : (dark
                                            ? AppColors.darkGrey
                                            : AppColors.textSecondary),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Customize your charts, readiness score & test data',
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
                    TextButton(
                      onPressed: activeCount > 0 ? _reset : null,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        visualDensity: VisualDensity.compact,
                      ),
                      child: Text(
                        'Reset',
                        style: TextStyle(
                          color: activeCount > 0
                              ? AppColors.primary
                              : (dark ? Colors.white24 : Colors.black26),
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Divider(
                height: 1,
                color: dark
                    ? AppColors.darkBorder
                    : const Color(0xFFF1F5F9),
              ),

              // ── Scrollable Filter Body ───────────────────────────────────
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Subject Filter Card
                      _FilterBlock(
                        icon: Iconsax.book_1_copy,
                        title: 'Subject Focus',
                        subtitle: 'Filter analytics to a specific subject',
                        activeValueLabel: _subject,
                        dark: dark,
                        child: _SubjectSelector(
                          availableSubjects:
                              widget.controller.availableSubjects.toList(),
                          selected: _subject,
                          onSelect: (val) => setState(() => _subject = val),
                          dark: dark,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // 2. Test Category
                      _FilterBlock(
                        icon: Icons.category_outlined,
                        title: 'Test Category',
                        subtitle: 'Exam format or syllabus coverage',
                        activeValueLabel: _testType == 'All Types'
                            ? 'All Categories'
                            : _testType,
                        dark: dark,
                        child: _TestCategoryGrid(
                          selected: _testType,
                          onSelect: (val) => setState(() => _testType = val),
                          dark: dark,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // 3. Test Mode / Timed Format
                      _FilterBlock(
                        icon: Icons.speed_rounded,
                        title: 'Exam Mode',
                        subtitle:
                            'Separate timed simulations from practice sessions',
                        activeValueLabel: {
                          TimedFilter.all: 'All Formats',
                          TimedFilter.timedOnly: 'Timed Only',
                          TimedFilter.untimeOnly: 'Practice Mode',
                        }[_timed]!,
                        dark: dark,
                        child: _FormatSelector(
                          selected: _timed,
                          onSelect: (val) => setState(() => _timed = val),
                          dark: dark,
                        ),
                      ),
                      const SizedBox(height: 14),

                      // 4. Score Benchmark
                      _FilterBlock(
                        icon: Icons.analytics_outlined,
                        title: 'Score Benchmark',
                        subtitle: 'Filter tests by achievement level',
                        activeValueLabel: {
                          ScoreFilter.all: 'All Scores',
                          ScoreFilter.good: 'Mastered (≥ 70%)',
                          ScoreFilter.poor: 'Needs Review (< 50%)',
                        }[_score]!,
                        dark: dark,
                        child: _ScoreBenchmarkSelector(
                          selected: _score,
                          onSelect: (val) => setState(() => _score = val),
                          dark: dark,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Bottom Action Footer ─────────────────────────────────────
              Container(
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 14),
                decoration: BoxDecoration(
                  color: dark ? AppColors.darkCard : AppColors.white,
                  border: Border(
                    top: BorderSide(
                      color: dark
                          ? AppColors.darkBorder
                          : const Color(0xFFF1F5F9),
                      width: 1,
                    ),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Quick Active Summary
                    if (activeCount > 0)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.filter_alt_outlined,
                              size: 13,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                [
                                  if (_subject != 'All Subjects') _subject,
                                  if (_testType != 'All Types' &&
                                      _testType != 'All Categories')
                                    _testType,
                                  if (_timed == TimedFilter.timedOnly)
                                    'Timed'
                                  else if (_timed == TimedFilter.untimeOnly)
                                    'Practice',
                                  if (_score == ScoreFilter.good)
                                    '≥ 70%'
                                  else if (_score == ScoreFilter.poor)
                                    '< 50%',
                                ].join(' • '),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Apply Button
                    SizedBox(
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
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check_rounded, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              activeCount > 0
                                  ? 'Apply Filters ($activeCount)'
                                  : 'Show All Analytics',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 14.5,
                              ),
                            ),
                          ],
                        ),
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

// ── Filter Block Wrapper ──────────────────────────────────────────────────────

class _FilterBlock extends StatelessWidget {
  const _FilterBlock({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.activeValueLabel,
    required this.child,
    required this.dark,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String activeValueLabel;
  final Widget child;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: dark
            ? Colors.white.withValues(alpha: 0.02)
            : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: dark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
          width: 0.9,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(
                    alpha: dark ? 0.20 : 0.08,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Icon(icon, size: 14, color: AppColors.primary),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                        color: dark ? AppColors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 10.5,
                        color: dark
                            ? AppColors.darkGrey
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                decoration: BoxDecoration(
                  color:
                      AppColors.primary.withValues(alpha: dark ? 0.20 : 0.10),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  activeValueLabel,
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 11),
          child,
        ],
      ),
    );
  }
}

// ── 1. Subject Selector ───────────────────────────────────────────────────────

class _SubjectSelector extends StatelessWidget {
  const _SubjectSelector({
    required this.availableSubjects,
    required this.selected,
    required this.onSelect,
    required this.dark,
  });

  final List<String> availableSubjects;
  final String selected;
  final void Function(String) onSelect;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final subjects = [
      'All Subjects',
      ...availableSubjects.where((s) => s != 'All Subjects'),
    ];

    return Wrap(
      spacing: 7,
      runSpacing: 7,
      children: subjects.map((subj) {
        final isSel = selected == subj;
        return InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => onSelect(subj),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6.5),
            decoration: BoxDecoration(
              color: isSel
                  ? AppColors.primary
                  : (dark
                      ? Colors.white.withValues(alpha: 0.04)
                      : Colors.white),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSel
                    ? AppColors.primary
                    : (dark ? AppColors.darkBorder : const Color(0xFFCBD5E1)),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isSel) ...[
                  const Icon(Icons.check_rounded,
                      size: 13, color: Colors.white),
                  const SizedBox(width: 4),
                ],
                Text(
                  subj,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                    color: isSel
                        ? Colors.white
                        : (dark ? AppColors.white : const Color(0xFF1E293B)),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── 2. Test Category Grid ─────────────────────────────────────────────────────

class _TestCategoryGrid extends StatelessWidget {
  const _TestCategoryGrid({
    required this.selected,
    required this.onSelect,
    required this.dark,
  });

  final String selected;
  final void Function(String) onSelect;
  final bool dark;

  static const _categories = [
    {'title': 'All Categories', 'icon': Icons.all_inclusive_rounded},
    {'title': 'Entrance Exam', 'icon': Icons.school_outlined},
    {'title': 'Model Exam', 'icon': Icons.star_border_rounded},
    {'title': 'Chapter Test', 'icon': Icons.menu_book_rounded},
    {'title': 'Grade Exam', 'icon': Icons.assignment_outlined},
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 7,
      runSpacing: 7,
      children: _categories.map((cat) {
        final title = cat['title'] as String;
        final icon = cat['icon'] as IconData;
        final isSel = selected == title ||
            (selected == 'All Types' && title == 'All Categories');

        return InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => onSelect(title),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: isSel
                  ? AppColors.primary
                  : (dark
                      ? Colors.white.withValues(alpha: 0.04)
                      : Colors.white),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSel
                    ? AppColors.primary
                    : (dark ? AppColors.darkBorder : const Color(0xFFCBD5E1)),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 15,
                  color: isSel
                      ? Colors.white
                      : (dark ? AppColors.white : const Color(0xFF334155)),
                ),
                const SizedBox(width: 5),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                    color: isSel
                        ? Colors.white
                        : (dark ? AppColors.white : const Color(0xFF1E293B)),
                  ),
                ),
                if (isSel) ...[
                  const SizedBox(width: 4),
                  const Icon(Icons.check_rounded,
                      size: 13, color: Colors.white),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── 3. Format Selector (Timed vs Practice) ────────────────────────────────────

class _FormatSelector extends StatelessWidget {
  const _FormatSelector({
    required this.selected,
    required this.onSelect,
    required this.dark,
  });

  final TimedFilter selected;
  final void Function(TimedFilter) onSelect;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final options = [
      {
        'value': TimedFilter.all,
        'title': 'All Formats',
        'icon': Icons.all_inclusive_rounded,
      },
      {
        'value': TimedFilter.timedOnly,
        'title': 'Timed Only',
        'icon': Icons.timer_outlined,
      },
      {
        'value': TimedFilter.untimeOnly,
        'title': 'Practice Mode',
        'icon': Icons.edit_note_rounded,
      },
    ];

    return Row(
      children: options.map((opt) {
        final val = opt['value'] as TimedFilter;
        final isSel = selected == val;
        final title = opt['title'] as String;
        final icon = opt['icon'] as IconData;

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => onSelect(val),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
                decoration: BoxDecoration(
                  color: isSel
                      ? AppColors.primary
                      : (dark
                          ? Colors.white.withValues(alpha: 0.04)
                          : Colors.white),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSel
                        ? AppColors.primary
                        : (dark
                            ? AppColors.darkBorder
                            : const Color(0xFFCBD5E1)),
                    width: 1,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      size: 16,
                      color: isSel
                          ? Colors.white
                          : (dark ? AppColors.white : const Color(0xFF334155)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                        color: isSel
                            ? Colors.white
                            : (dark
                                ? AppColors.white
                                : const Color(0xFF1E293B)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── 4. Score Benchmark Selector ───────────────────────────────────────────────

class _ScoreBenchmarkSelector extends StatelessWidget {
  const _ScoreBenchmarkSelector({
    required this.selected,
    required this.onSelect,
    required this.dark,
  });

  final ScoreFilter selected;
  final void Function(ScoreFilter) onSelect;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final options = [
      {
        'value': ScoreFilter.all,
        'title': 'All Scores',
        'badge': '100%',
        'badgeColor': AppColors.primary,
        'icon': Icons.bar_chart_rounded,
      },
      {
        'value': ScoreFilter.good,
        'title': 'Mastered',
        'badge': '≥ 70%',
        'badgeColor': const Color(0xFF10B981),
        'icon': Icons.check_circle_outline_rounded,
      },
      {
        'value': ScoreFilter.poor,
        'title': 'Needs Work',
        'badge': '< 50%',
        'badgeColor': const Color(0xFFD97706),
        'icon': Icons.warning_amber_rounded,
      },
    ];

    return Row(
      children: options.map((opt) {
        final val = opt['value'] as ScoreFilter;
        final isSel = selected == val;
        final title = opt['title'] as String;
        final badge = opt['badge'] as String;
        final badgeColor = opt['badgeColor'] as Color;
        final icon = opt['icon'] as IconData;

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => onSelect(val),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
                decoration: BoxDecoration(
                  color: isSel
                      ? AppColors.primary
                      : (dark
                          ? Colors.white.withValues(alpha: 0.04)
                          : Colors.white),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSel
                        ? AppColors.primary
                        : (dark
                            ? AppColors.darkBorder
                            : const Color(0xFFCBD5E1)),
                    width: 1,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          icon,
                          size: 15,
                          color: isSel ? Colors.white : badgeColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          badge,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: isSel ? Colors.white70 : badgeColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                        color: isSel
                            ? Colors.white
                            : (dark
                                ? AppColors.white
                                : const Color(0xFF1E293B)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
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
          icon: Iconsax.book_1_copy,
          label: controller.selectedSubject.value,
          onRemove: () => controller.applyFilters(subject: 'All Subjects'),
        ),
      );
    }
    if (controller.selectedTestType.value != 'All Types' &&
        controller.selectedTestType.value != 'All Categories') {
      chips.add(
        _DismissChip(
          icon: Icons.category_outlined,
          label: controller.selectedTestType.value,
          onRemove: () => controller.applyFilters(testType: 'All Categories'),
        ),
      );
    }
    if (controller.selectedTimed.value != TimedFilter.all) {
      chips.add(
        _DismissChip(
          icon: Icons.timer_outlined,
          label: controller.selectedTimed.value == TimedFilter.timedOnly
              ? 'Timed Only'
              : 'Practice Mode',
          onRemove: () => controller.applyFilters(timed: TimedFilter.all),
        ),
      );
    }
    if (controller.selectedScore.value != ScoreFilter.all) {
      chips.add(
        _DismissChip(
          icon: controller.selectedScore.value == ScoreFilter.good
              ? Icons.check_circle_outline_rounded
              : Icons.warning_amber_rounded,
          label: controller.selectedScore.value == ScoreFilter.good
              ? 'Mastered (≥ 70%)'
              : 'Needs Review (< 50%)',
          accentColor: controller.selectedScore.value == ScoreFilter.good
              ? const Color(0xFF10B981)
              : const Color(0xFFD97706),
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
            InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: controller.resetFilters,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Text(
                  'Reset all',
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
  const _DismissChip({
    required this.label,
    required this.onRemove,
    this.icon,
    this.accentColor,
  });

  final String label;
  final VoidCallback onRemove;
  final IconData? icon;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final dark = AppHelperFunctions.isDark(context);
    final color = accentColor ?? AppColors.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: dark ? 0.2 : 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 5),
          GestureDetector(
            onTap: onRemove,
            child: Icon(
              Icons.close_rounded,
              size: 13,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
