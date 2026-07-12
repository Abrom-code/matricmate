import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:matricmate/common/widgets/exam/bb_table_widget.dart';
import 'package:matricmate/features/exam/screens/question/widgets/image_section.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/helpers/bb_table_parser.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';
import 'package:matricmate/utils/helpers/rich_text_parser.dart';

/// A reusable collapsible explanation box used on both the question screen
/// and the review screen.
///
/// - Tap anywhere on the box to expand/collapse.
/// - Language toggle pill is only visible when expanded.
/// - [languageSelected] is an [RxString] so it reactively rebuilds.
/// - [onLanguageChange] switches the language without collapsing the box.
class AppExplanationBox extends StatelessWidget {
  const AppExplanationBox({
    super.key,
    required this.explanationEn,
    required this.explanationAm,
    required this.expanded,
    required this.onToggle,
    required this.languageSelected,
    required this.onLanguageChange,
    this.explanationImageUrl,
  });

  final String explanationEn;
  final String explanationAm;
  final bool expanded;
  final VoidCallback onToggle;
  final RxString languageSelected;
  final ValueChanged<String> onLanguageChange;
  final String? explanationImageUrl;

  @override
  Widget build(BuildContext context) {
    final dark = AppHelperFunctions.isDark(context);

    // Tinted teal background — signals "explanation" without being loud
    final bgColor = dark
        ? AppColors.primary.withValues(alpha: 0.10)
        : AppColors.primary.withValues(alpha: 0.06);
    final borderColor = AppColors.primary.withValues(alpha: dark ? 0.30 : 0.25);

    return GestureDetector(
      onTap: onToggle,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: bgColor.withValues(alpha: .06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.lightbulb_outline_rounded,
                        color: AppColors.primary,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Explanation',
                        style: Theme.of(context).textTheme.labelSmall!.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      // language toggle — absorbs its tap so it doesn't
                      // bubble up and trigger the outer toggle
                      if (expanded)
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {},
                          child: Obx(
                            () => _LangToggle(
                              selected: languageSelected.value,
                              dark: dark,
                              onTap: onLanguageChange,
                            ),
                          ),
                        ),
                      if (!expanded)
                        Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: AppColors.primary.withValues(alpha: 0.8),
                          size: 20,
                        ),
                      const SizedBox(width: 4),
                    ],
                  ),
                ],
              ),
            ),

            // ── Body ────────────────────────────────────────────────────
            if (expanded) ...[
              Divider(
                height: 1,
                color: AppColors.primary.withValues(alpha: 0.15),
              ),
              Obx(() {
                final text = languageSelected.value == 'AM'
                    ? explanationAm
                    : explanationEn;
                final baseStyle = GoogleFonts.lora(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  height: 1.75,
                  letterSpacing: 0.1,
                  color: dark
                      ? AppColors.white.withValues(alpha: 0.85)
                      : AppColors.darkerGrey,
                );
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Table-aware rendering ──────────────────────────
                      // Split the explanation into plain-text and table
                      // segments, render each in order. Falls back to a
                      // single Text.rich when no [table] tags are present.
                      if (BBTableParser.containsTable(text))
                        ..._buildSegments(text, baseStyle)
                      else
                        Text.rich(RichTextParser.parse(text, baseStyle)),
                      // ── Optional explanation image ─────────────────────
                      if (explanationImageUrl != null &&
                          explanationImageUrl!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        ImageSection(imgUrl: explanationImageUrl),
                      ],
                    ],
                  ),
                );
              }),
            ] else
              const SizedBox(height: 4),
          ],
        ),
      ),
    );
  }
}

// ── Segment renderer helper ───────────────────────────────────────────────────

/// Converts BBTableParser segments into a flat list of widgets for use inside
/// a [Column]. Plain-text segments go through [RichTextParser]; table segments
/// are rendered by [BBTableWidget].
List<Widget> _buildSegments(String text, TextStyle baseStyle) {
  final segments = BBTableParser.splitSegments(text);
  final widgets = <Widget>[];

  for (final seg in segments) {
    if (seg.isTable) {
      widgets.add(const SizedBox(height: 8));
      widgets.add(BBTableWidget(rows: seg.tableRows!, baseStyle: baseStyle));
      widgets.add(const SizedBox(height: 8));
    } else {
      widgets.add(Text.rich(RichTextParser.parse(seg.text!, baseStyle)));
    }
  }

  return widgets;
}

// ── Language toggle pill ─────────────────────────────────────────────────────

class _LangToggle extends StatelessWidget {
  const _LangToggle({
    required this.selected,
    required this.dark,
    required this.onTap,
  });

  final String selected;
  final bool dark;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: dark
            ? AppColors.primary.withValues(alpha: 0.18)
            : AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [_pill('En', 'EN'), _pill('አማ', 'AM')],
      ),
    );
  }

  Widget _pill(String label, String value) {
    final isSelected = selected == value;
    return GestureDetector(
      onTap: () => onTap(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? dark
                    ? AppColors.primary.withValues(alpha: 0.35)
                    : AppColors.primary.withValues(alpha: 0.18)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isSelected
                ? AppColors.primary
                : dark
                ? AppColors.primary.withValues(alpha: 0.6)
                : AppColors.primary.withValues(alpha: 0.55),
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
