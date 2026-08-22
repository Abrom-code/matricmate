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
  late StreamFilter _stream;

  @override
  void initState() {
    super.initState();
    final c = widget.controller;
    _subject = c.selectedSubject.value;
    _testType = c.selectedTestType.value;
    _stream = c.selectedStream.value;
  }

  void _reset() => setState(() {
    _subject = 'All Subjects';
    _testType = 'All Types';
    _stream = StreamFilter.all;
  });

  void _apply() {
    widget.controller.applyFilters(
      subject: _subject,
      testType: _testType,
      stream: _stream,
    );
    Get.back();
  }

  @override
  Widget build(BuildContext context) {
    final dark = AppHelperFunctions.isDark(context);

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
              top: Radius.circular(28),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: dark ? 0.35 : 0.08),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Handle ──────────────────────────────────────────────
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 42,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: dark ? AppColors.darkBorder : const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // ── Header ──────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(
                              alpha: dark ? 0.22 : 0.1,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Center(
                            child: Icon(
                              Iconsax.filter_copy,
                              size: 16,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Filter Analytics',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                            color: dark
                                ? AppColors.white
                                : const Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: _reset,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                      ),
                      child: const Text(
                        'Reset all',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Divider(
                height: 1,
                color: dark
                    ? AppColors.darkBorder
                    : const Color(0xFFF1F5F9),
              ),

              // ── Scrollable Body ──────────────────────────────────────
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1 — Stream Category
                      _ModernSectionHeader(
                        icon: Iconsax.hierarchy_copy,
                        title: 'Academic Stream',
                        dark: dark,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _StreamCard(
                            title: 'All Streams',
                            icon: Icons.all_inclusive_rounded,
                            isSelected: _stream == StreamFilter.all,
                            onTap: () => setState(() => _stream = StreamFilter.all),
                            dark: dark,
                          ),
                          const SizedBox(width: 8),
                          _StreamCard(
                            title: 'Natural',
                            icon: Icons.science_outlined,
                            isSelected: _stream == StreamFilter.natural,
                            onTap: () =>
                                setState(() => _stream = StreamFilter.natural),
                            dark: dark,
                          ),
                          const SizedBox(width: 8),
                          _StreamCard(
                            title: 'Social',
                            icon: Icons.public_rounded,
                            isSelected: _stream == StreamFilter.social,
                            onTap: () =>
                                setState(() => _stream = StreamFilter.social),
                            dark: dark,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // 2 — Test Type
                      _ModernSectionHeader(
                        icon: Iconsax.note_21_copy,
                        title: 'Test Category',
                        dark: dark,
                      ),
                      const SizedBox(height: 10),
                      _ModernChipGroup<String>(
                        items: widget.controller.availableTestTypes.toList(),
                        selected: _testType,
                        labelOf: (s) => s,
                        onSelect: (s) => setState(() => _testType = s),
                      ),
                      const SizedBox(height: 20),

                      // 3 — Subject
                      _ModernSectionHeader(
                        icon: Iconsax.book_1_copy,
                        title: 'Subject',
                        dark: dark,
                      ),
                      const SizedBox(height: 10),
                      _ModernChipGroup<String>(
                        items: widget.controller.availableSubjects.toList(),
                        selected: _subject,
                        labelOf: (s) => s,
                        onSelect: (s) => setState(() => _subject = s),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Apply Button Footer ──────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: _apply,
                    child: const Text(
                      'Apply Filters',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        height: 1.0,
                        color: Colors.white,
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

// ── Stream Card ──────────────────────────────────────────────────────────────

class _StreamCard extends StatelessWidget {
  const _StreamCard({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    required this.dark,
  });

  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary
                : (dark
                    ? Colors.white.withValues(alpha: 0.05)
                    : const Color(0xFFF8FAFC)),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? AppColors.primary
                  : (dark
                      ? AppColors.darkBorder
                      : const Color(0xFFE2E8F0)),
              width: 1.2,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected
                    ? Colors.white
                    : (dark ? AppColors.white : const Color(0xFF334155)),
              ),
              const SizedBox(height: 6),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected
                      ? Colors.white
                      : (dark ? AppColors.white : const Color(0xFF1E293B)),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Section Header ────────────────────────────────────────────────────────────

class _ModernSectionHeader extends StatelessWidget {
  const _ModernSectionHeader({
    required this.icon,
    required this.title,
    required this.dark,
  });

  final IconData icon;
  final String title;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 15,
          color: AppColors.primary,
        ),
        const SizedBox(width: 7),
        Text(
          title,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: dark ? AppColors.white : const Color(0xFF1E293B),
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }
}

// ── Modern Chip Group ─────────────────────────────────────────────────────────

class _ModernChipGroup<T> extends StatelessWidget {
  const _ModernChipGroup({
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
    final dark = AppHelperFunctions.isDark(context);

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
        final isSel = item == selected;
        return GestureDetector(
          onTap: () => onSelect(item),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7.5),
            decoration: BoxDecoration(
              color: isSel
                  ? AppColors.primary
                  : (dark
                      ? Colors.white.withValues(alpha: 0.05)
                      : const Color(0xFFF8FAFC)),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSel
                    ? AppColors.primary
                    : (dark
                        ? AppColors.darkBorder
                        : const Color(0xFFE2E8F0)),
                width: 1.1,
              ),
            ),
            child: Text(
              labelOf(item),
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                color: isSel
                    ? AppColors.white
                    : (dark ? AppColors.white : const Color(0xFF334155)),
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
          label: controller.selectedSubject.value,
          onRemove: () => controller.applyFilters(subject: 'All Subjects'),
        ),
      );
    }
    if (controller.selectedTestType.value != 'All Types') {
      chips.add(
        _DismissChip(
          label: controller.selectedTestType.value,
          onRemove: () => controller.applyFilters(testType: 'All Types'),
        ),
      );
    }
    if (controller.selectedStream.value != StreamFilter.all) {
      final labels = {
        StreamFilter.natural: 'Natural Science',
        StreamFilter.social: 'Social Science',
        StreamFilter.common: 'Common',
      };
      chips.add(
        _DismissChip(
          label: labels[controller.selectedStream.value] ?? 'Stream',
          onRemove: () => controller.applyFilters(stream: StreamFilter.all),
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
                    color: AppColors.error,
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
        color: AppColors.primary.withValues(alpha: dark ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 5),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(
              Icons.close_rounded,
              size: 14,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
