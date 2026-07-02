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

  @override
  void initState() {
    super.initState();
    _subject = widget.controller.selectedSubject.value ?? 'All Subjects';
    _testType = widget.controller.selectedTestType.value ?? 'All Types';
    _timeFilter = widget.controller.selectedTimeFilter.value;
  }

  static const _timeLabels = {
    TimeFilter.all: 'All time',
    TimeFilter.lastWeek: 'Last 7 days',
    TimeFilter.lastMonth: 'Last 30 days',
    TimeFilter.last3Months: 'Last 3 months',
  };

  @override
  Widget build(BuildContext context) {
    final dark = AppHelperFunctions.isDark(context);
    final subjects = widget.controller.availableSubjects;
    final types = widget.controller.availableTestTypes;

    return Container(
      padding: EdgeInsets.only(
        left: AppSizes.defaultSpace,
        right: AppSizes.defaultSpace,
        top: AppSizes.md,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSizes.defaultSpace,
      ),
      decoration: BoxDecoration(
        color: dark ? AppColors.dark : AppColors.white,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSizes.lg),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
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
          const SizedBox(height: AppSizes.spaceBtwItems),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filter Analytics',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _subject = 'All Subjects';
                    _testType = 'All Types';
                    _timeFilter = TimeFilter.all;
                  });
                },
                child: const Text(
                  'Reset',
                  style: TextStyle(color: AppColors.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.spaceBtwItems),

          // Subject filter
          const _SectionLabel(label: 'Subject'),
          const SizedBox(height: AppSizes.sm),
          Obx(() => _ChipGroup<String>(
                items: subjects,
                selected: _subject,
                labelOf: (s) => s,
                onSelect: (s) => setState(() => _subject = s),
              )),
          const SizedBox(height: AppSizes.spaceBtwItems),

          // Test type filter
          const _SectionLabel(label: 'Test type'),
          const SizedBox(height: AppSizes.sm),
          Obx(() => _ChipGroup<String>(
                items: types,
                selected: _testType,
                labelOf: (s) => s,
                onSelect: (s) => setState(() => _testType = s),
              )),
          const SizedBox(height: AppSizes.spaceBtwItems),

          // Time filter
          const _SectionLabel(label: 'Time period'),
          const SizedBox(height: AppSizes.sm),
          _ChipGroup<TimeFilter>(
            items: TimeFilter.values,
            selected: _timeFilter,
            labelOf: (f) => _timeLabels[f]!,
            onSelect: (f) => setState(() => _timeFilter = f),
          ),
          const SizedBox(height: AppSizes.spaceBtwSections),

          // Apply button
          SizedBox(
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
              onPressed: () {
                widget.controller.applyFilters(
                  subject: _subject,
                  testType: _testType,
                  timeFilter: _timeFilter,
                );
                Get.back();
              },
              child: const Text(
                'Apply Filters',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

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
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((item) {
        final isSelected = item == selected;
        return GestureDetector(
          onTap: () => onSelect(item),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
