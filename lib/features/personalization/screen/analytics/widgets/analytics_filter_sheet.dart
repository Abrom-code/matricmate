import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matricmate/features/personalization/controller/analytics_controller.dart';
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
  late String _subject;
  late String _testType;
  late TimeFilter _timeFilter;

  static const _timeLabels = {
    TimeFilter.all: 'All time',
    TimeFilter.lastWeek: 'Last 7 days',
    TimeFilter.lastMonth: 'Last 30 days',
    TimeFilter.last3Months: 'Last 3 months',
  };

  @override
  void initState() {
    super.initState();
    // Snapshot current selections when the sheet opens
    _subject    = widget.controller.selectedSubject.value ?? 'All Subjects';
    _testType   = widget.controller.selectedTestType.value ?? 'All Types';
    _timeFilter = widget.controller.selectedTimeFilter.value;
  }

  void _reset() => setState(() {
        _subject    = 'All Subjects';
        _testType   = 'All Types';
        _timeFilter = TimeFilter.all;
      });

  void _apply() {
    widget.controller.applyFilters(
      subject:    _subject,
      testType:   _testType,
      timeFilter: _timeFilter,
    );
    Get.back();
  }

  @override
  Widget build(BuildContext context) {
    final dark = AppHelperFunctions.isDark(context);

    return SafeArea(
      // Keep content above nav bar / keyboard
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          // Let the sheet be at most 85% of screen height and scroll if needed
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          decoration: BoxDecoration(
            color: dark ? AppColors.dark : AppColors.white,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppSizes.lg),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Drag handle ─────────────────────────────────────
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

              // ── Header row ──────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.defaultSpace,
                ),
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
                      child: const Text(
                        'Reset',
                        style: TextStyle(color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Scrollable filter content ────────────────────────
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSizes.defaultSpace,
                    AppSizes.sm,
                    AppSizes.defaultSpace,
                    AppSizes.defaultSpace,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Subject chips — read RxList inside setState callback,
                      // no Obx needed; list is already populated before sheet opens
                      const _SectionLabel(label: 'Subject'),
                      const SizedBox(height: AppSizes.sm),
                      _ChipGroup<String>(
                        items: widget.controller.availableSubjects.toList(),
                        selected: _subject,
                        labelOf: (s) => s,
                        onSelect: (s) => setState(() => _subject = s),
                      ),
                      const SizedBox(height: AppSizes.spaceBtwItems),

                      // Test type chips
                      const _SectionLabel(label: 'Test type'),
                      const SizedBox(height: AppSizes.sm),
                      _ChipGroup<String>(
                        items: widget.controller.availableTestTypes.toList(),
                        selected: _testType,
                        labelOf: (s) => s,
                        onSelect: (s) => setState(() => _testType = s),
                      ),
                      const SizedBox(height: AppSizes.spaceBtwItems),

                      // Time period chips
                      const _SectionLabel(label: 'Time period'),
                      const SizedBox(height: AppSizes.sm),
                      _ChipGroup<TimeFilter>(
                        items: TimeFilter.values,
                        selected: _timeFilter,
                        labelOf: (f) => _timeLabels[f]!,
                        onSelect: (f) => setState(() => _timeFilter = f),
                      ),
                      const SizedBox(height: AppSizes.spaceBtwSections),
                    ],
                  ),
                ),
              ),

              // ── Apply button — pinned at the bottom ──────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSizes.defaultSpace,
                  0,
                  AppSizes.defaultSpace,
                  AppSizes.defaultSpace,
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppSizes.borderRadiusLg),
                      ),
                    ),
                    onPressed: _apply,
                    child: const Text(
                      'Apply Filters',
                      style: TextStyle(fontWeight: FontWeight.w600),
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

// ── Section label ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
        color: AppColors.textSecondary,
      ),
    );
  }
}

// ── Chip group ───────────────────────────────────────────────────────────────

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
      return const Text(
        'No options available',
        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((item) {
        final isSelected = item == selected;
        return GestureDetector(
          onTap: () => onSelect(item),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary
                  : AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? AppColors.primary
                    : AppColors.primary.withValues(alpha: 0.25),
              ),
            ),
            child: Text(
              labelOf(item),
              style: TextStyle(
                fontSize: 13,
                fontWeight:
                    isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? AppColors.white : AppColors.primary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
