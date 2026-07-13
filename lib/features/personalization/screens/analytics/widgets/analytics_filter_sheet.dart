import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matricmate/features/personalization/controllers/analytics_controller.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/constants/sizes.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

class AnalyticsFilterSheet extends StatefulWidget {
  const AnalyticsFilterSheet({super.key, required this.controller});
  final AnalyticsController controller;

  @override
  State<AnalyticsFilterSheet> createState() => _AnalyticsFilterSheetState();
}

class _AnalyticsFilterSheetState extends State<AnalyticsFilterSheet> {
  // Local selections — committed only when Apply is tapped
  late String       _subject;
  late String       _testType;
  late TimeFilter   _time;
  late GradeFilter  _grade;
  late StreamFilter _stream;
  late ScoreFilter  _score;
  late TimedFilter  _timed;

  @override
  void initState() {
    super.initState();
    final c     = widget.controller;
    _subject    = c.selectedSubject.value;
    _testType   = c.selectedTestType.value;
    _time       = c.selectedTimeFilter.value;
    _grade      = c.selectedGrade.value;
    _stream     = c.selectedStream.value;
    _score      = c.selectedScore.value;
    _timed      = c.selectedTimed.value;
  }

  void _reset() => setState(() {
    _subject = 'All Subjects';
    _testType = 'All Types';
    _time    = TimeFilter.all;
    _grade   = GradeFilter.all;
    _stream  = StreamFilter.all;
    _score   = ScoreFilter.all;
    _timed   = TimedFilter.all;
  });

  void _apply() {
    widget.controller.applyFilters(
      subject:    _subject,
      testType:   _testType,
      timeFilter: _time,
      grade:      _grade,
      stream:     _stream,
      score:      _score,
      timed:      _timed,
    );
    Get.back();
  }

  @override
  Widget build(BuildContext context) {
    final dark = AppHelperFunctions.isDark(context);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.88,
          ),
          decoration: BoxDecoration(
            color: dark ? AppColors.darkCard : AppColors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSizes.lg)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Handle ──────────────────────────────────────────────
              const SizedBox(height: AppSizes.sm),
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.grey,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.sm),

              // ── Header ──────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.defaultSpace),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Filter Analytics',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: _reset,
                      child: const Text('Reset all', style: TextStyle(color: AppColors.primary)),
                    ),
                  ],
                ),
              ),

              // ── Scrollable body ──────────────────────────────────────
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSizes.defaultSpace, AppSizes.sm,
                    AppSizes.defaultSpace, AppSizes.md,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1 — Subject
                      _FilterSection(
                        label: 'Subject',
                        child: _ChipGroup<String>(
                          items: widget.controller.availableSubjects.toList(),
                          selected: _subject,
                          labelOf: (s) => s,
                          onSelect: (s) => setState(() => _subject = s),
                        ),
                      ),

                      // 2 — Test type
                      _FilterSection(
                        label: 'Test type',
                        child: _ChipGroup<String>(
                          items: widget.controller.availableTestTypes.toList(),
                          selected: _testType,
                          labelOf: (s) => s,
                          onSelect: (s) => setState(() => _testType = s),
                        ),
                      ),

                      // 3 — Grade
                      _FilterSection(
                        label: 'Grade',
                        child: _ChipGroup<GradeFilter>(
                          items: GradeFilter.values,
                          selected: _grade,
                          labelOf: _gradeLabel,
                          onSelect: (g) => setState(() => _grade = g),
                        ),
                      ),

                      // 4 — Stream
                      _FilterSection(
                        label: 'Stream',
                        child: _ChipGroup<StreamFilter>(
                          items: StreamFilter.values,
                          selected: _stream,
                          labelOf: _streamLabel,
                          onSelect: (s) => setState(() => _stream = s),
                        ),
                      ),

                      // 5 — Score range
                      _FilterSection(
                        label: 'Score range',
                        child: _ChipGroup<ScoreFilter>(
                          items: ScoreFilter.values,
                          selected: _score,
                          labelOf: _scoreLabel,
                          onSelect: (s) => setState(() => _score = s),
                        ),
                      ),

                      // 6 — Timed
                      _FilterSection(
                        label: 'Test format',
                        child: _ChipGroup<TimedFilter>(
                          items: TimedFilter.values,
                          selected: _timed,
                          labelOf: _timedLabel,
                          onSelect: (t) => setState(() => _timed = t),
                        ),
                      ),

                      // 7 — Time period
                      _FilterSection(
                        label: 'Time period',
                        child: _ChipGroup<TimeFilter>(
                          items: TimeFilter.values,
                          selected: _time,
                          labelOf: _timeLabel,
                          onSelect: (t) => setState(() => _time = t),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Apply button ─────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSizes.defaultSpace, 0,
                  AppSizes.defaultSpace, AppSizes.defaultSpace,
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppSizes.borderRadiusLg),
                      ),
                    ),
                    onPressed: _apply,
                    child: const Text(
                      'Apply Filters',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
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

  // ── Label helpers ────────────────────────────────────────────────────────

  String _gradeLabel(GradeFilter g) => const {
    GradeFilter.all:     'All grades',
    GradeFilter.grade9:  'Grade 9',
    GradeFilter.grade10: 'Grade 10',
    GradeFilter.grade11: 'Grade 11',
    GradeFilter.grade12: 'Grade 12',
  }[g]!;

  String _streamLabel(StreamFilter s) => const {
    StreamFilter.all:     'All streams',
    StreamFilter.natural: 'Natural',
    StreamFilter.social:  'Social',
    StreamFilter.common:  'Common',
  }[s]!;

  String _scoreLabel(ScoreFilter s) => const {
    ScoreFilter.all:     'All scores',
    ScoreFilter.poor:    'Poor  < 50%',
    ScoreFilter.average: 'Average 50–70%',
    ScoreFilter.good:    'Good  ≥ 70%',
  }[s]!;

  String _timedLabel(TimedFilter t) => const {
    TimedFilter.all:        'All formats',
    TimedFilter.timedOnly:  'Timed only',
    TimedFilter.untimeOnly: 'Untimed only',
  }[t]!;

  String _timeLabel(TimeFilter t) => const {
    TimeFilter.all:          'All time',
    TimeFilter.lastWeek:     'Last 7 days',
    TimeFilter.lastMonth:    'Last 30 days',
    TimeFilter.last3Months:  'Last 3 months',
  }[t]!;
}

// ── Active filter chips row (shown in the analytics screen) ──────────────────

class ActiveFilterRow extends StatelessWidget {
  const ActiveFilterRow({super.key, required this.controller});
  final AnalyticsController controller;

  @override
  Widget build(BuildContext context) {
    final chips = <_DismissChip>[];

    if (controller.selectedSubject.value != 'All Subjects') {
      chips.add(_DismissChip(
        label: controller.selectedSubject.value,
        onRemove: () => controller.applyFilters(subject: 'All Subjects'),
      ));
    }
    if (controller.selectedTestType.value != 'All Types') {
      chips.add(_DismissChip(
        label: controller.selectedTestType.value,
        onRemove: () => controller.applyFilters(testType: 'All Types'),
      ));
    }
    if (controller.selectedGrade.value != GradeFilter.all) {
      final labels = {
        GradeFilter.grade9: 'Grade 9', GradeFilter.grade10: 'Grade 10',
        GradeFilter.grade11: 'Grade 11', GradeFilter.grade12: 'Grade 12',
      };
      chips.add(_DismissChip(
        label: labels[controller.selectedGrade.value]!,
        onRemove: () => controller.applyFilters(grade: GradeFilter.all),
      ));
    }
    if (controller.selectedStream.value != StreamFilter.all) {
      final labels = {
        StreamFilter.natural: 'Natural', StreamFilter.social: 'Social',
        StreamFilter.common: 'Common',
      };
      chips.add(_DismissChip(
        label: labels[controller.selectedStream.value]!,
        onRemove: () => controller.applyFilters(stream: StreamFilter.all),
      ));
    }
    if (controller.selectedScore.value != ScoreFilter.all) {
      final labels = {
        ScoreFilter.poor: 'Poor < 50%',
        ScoreFilter.average: 'Avg 50–70%',
        ScoreFilter.good: 'Good ≥ 70%',
      };
      chips.add(_DismissChip(
        label: labels[controller.selectedScore.value]!,
        onRemove: () => controller.applyFilters(score: ScoreFilter.all),
      ));
    }
    if (controller.selectedTimed.value != TimedFilter.all) {
      chips.add(_DismissChip(
        label: controller.selectedTimed.value == TimedFilter.timedOnly
            ? 'Timed only' : 'Untimed only',
        onRemove: () => controller.applyFilters(timed: TimedFilter.all),
      ));
    }
    if (controller.selectedTimeFilter.value != TimeFilter.all) {
      final labels = {
        TimeFilter.lastWeek: 'Last 7d',
        TimeFilter.lastMonth: 'Last 30d',
        TimeFilter.last3Months: 'Last 3mo',
      };
      chips.add(_DismissChip(
        label: labels[controller.selectedTimeFilter.value]!,
        onRemove: () => controller.applyFilters(timeFilter: TimeFilter.all),
      ));
    }

    if (chips.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.spaceBtwItems),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            ...chips.map((c) => Padding(
              padding: const EdgeInsets.only(right: 6), child: c,
            )),
            GestureDetector(
              onTap: controller.resetFilters,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                child: Text('Clear all',
                  style: TextStyle(fontSize: 12, color: AppColors.error, fontWeight: FontWeight.w600),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w500)),
          const SizedBox(width: 4),
          GestureDetector(onTap: onRemove, child: const Icon(Icons.close, size: 14, color: AppColors.primary)),
        ],
      ),
    );
  }
}

// ── Filter section wrapper ────────────────────────────────────────────────────

class _FilterSection extends StatelessWidget {
  const _FilterSection({required this.label, required this.child});
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSizes.spaceBtwItems),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 11, fontWeight: FontWeight.w700,
              letterSpacing: 1.2, color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSizes.sm),
          child,
        ],
      ),
    );
  }
}

// ── Chip group ────────────────────────────────────────────────────────────────

class _ChipGroup<T> extends StatelessWidget {
  const _ChipGroup({
    required this.items,
    required this.selected,
    required this.labelOf,
    required this.onSelect,
  });

  final List<T> items;
  final T selected;
  final String Function(T) labelOf;
  final void Function(T) onSelect;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Text('No options', style: TextStyle(fontSize: 12, color: AppColors.textSecondary));
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((item) {
        final isSel = item == selected;
        return GestureDetector(
          onTap: () => onSelect(item),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 130),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSel ? AppColors.primary : AppColors.primary.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSel ? AppColors.primary : AppColors.primary.withValues(alpha: 0.25),
              ),
            ),
            child: Text(
              labelOf(item),
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSel ? FontWeight.w600 : FontWeight.w400,
                color: isSel ? AppColors.white : AppColors.primary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
