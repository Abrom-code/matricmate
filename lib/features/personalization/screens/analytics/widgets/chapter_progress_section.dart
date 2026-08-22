import 'package:flutter/material.dart';
import 'package:matricmate/features/personalization/controllers/analytics_controller.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

class ChapterProgressSection extends StatefulWidget {
  const ChapterProgressSection({super.key, required this.controller});
  final AnalyticsController controller;

  @override
  State<ChapterProgressSection> createState() => _ChapterProgressSectionState();
}

class _ChapterProgressSectionState extends State<ChapterProgressSection> {
  static const int _previewCount = 3;
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final dark = AppHelperFunctions.isDark(context);
    final chapters = widget.controller.chapterStats;
    final hasMore = chapters.length > _previewCount;
    final visibleChapters = _expanded
        ? chapters
        : chapters.take(_previewCount).toList();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: dark ? AppColors.darkCard : AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: dark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? 0.2 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ────────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Chapter Progress',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                  color: dark ? AppColors.white : const Color(0xFF0F172A),
                ),
              ),
              if (hasMore)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(
                      alpha: dark ? 0.2 : 0.08,
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${chapters.length} chapters',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),

          // ── Chapter rows ─────────────────────────────────────────
          if (chapters.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'No chapter progress yet',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            )
          else
            AnimatedSize(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeInOut,
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: visibleChapters.length,
                separatorBuilder: (_, __) => Divider(
                  height: 20,
                  thickness: 0.8,
                  color: dark
                      ? Colors.white.withValues(alpha: 0.06)
                      : const Color(0xFFF1F5F9),
                ),
                itemBuilder: (_, i) => _ChapterRow(
                  stat: visibleChapters[i],
                  dark: dark,
                ),
              ),
            ),

          // ── See all / Show less button ────────────────────────────
          if (hasMore) ...[
            const SizedBox(height: 10),
            InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(
                    alpha: dark ? 0.15 : 0.06,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _expanded
                          ? 'Show less'
                          : 'See all ${chapters.length} chapters',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      _expanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      size: 18,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Chapter row ───────────────────────────────────────────────────────────────

class _ChapterRow extends StatelessWidget {
  const _ChapterRow({required this.stat, required this.dark});
  final ChapterStat stat;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final attempted = stat.score != null;
    final pct = (stat.score ?? 0.0).clamp(0.0, 100.0);

    Color barColor = AppColors.primary;
    if (pct < 50) {
      barColor = const Color(0xFFEF4444);
    } else if (pct < 70) {
      barColor = const Color(0xFFF59E0B);
    } else {
      barColor = const Color(0xFF10B981);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                stat.title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: dark ? AppColors.white : const Color(0xFF1E293B),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            attempted
                ? Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 1.5,
                    ),
                    decoration: BoxDecoration(
                      color: barColor.withValues(alpha: dark ? 0.2 : 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${pct.toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: barColor,
                      ),
                    ),
                  )
                : Text(
                    'Not attempted',
                    style: TextStyle(
                      color: dark
                          ? AppColors.darkGrey
                          : AppColors.textSecondary,
                      fontSize: 11.5,
                    ),
                  ),
          ],
        ),
        if (attempted) ...[
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct / 100,
              minHeight: 6,
              backgroundColor: dark
                  ? Colors.white.withValues(alpha: 0.08)
                  : const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),
        ],
      ],
    );
  }
}
