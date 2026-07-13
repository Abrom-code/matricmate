import 'package:flutter/material.dart';
import 'package:matricmate/features/personalization/controllers/analytics_controller.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/constants/sizes.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

class ChapterProgressSection extends StatefulWidget {
  const ChapterProgressSection({super.key, required this.controller});
  final AnalyticsController controller;

  @override
  State<ChapterProgressSection> createState() =>
      _ChapterProgressSectionState();
}

class _ChapterProgressSectionState extends State<ChapterProgressSection> {
  static const int _previewCount = 3;
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final dark = AppHelperFunctions.isDark(context);
    final chapters = widget.controller.chapterStats;
    final hasMore = chapters.length > _previewCount;
    final visibleChapters =
        _expanded ? chapters : chapters.take(_previewCount).toList();

    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: dark ? AppColors.darkCard : AppColors.white,
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusLg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            spreadRadius: -2,
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
                'Chapter progress',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              if (hasMore)
                Text(
                  '${chapters.length} chapters',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSizes.spaceBtwItems),

          // ── Chapter rows ─────────────────────────────────────────
          if (chapters.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'No data yet',
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
                separatorBuilder: (_, __) =>
                    const Divider(height: 24, thickness: 0.5),
                itemBuilder: (_, i) =>
                    _ChapterRow(stat: visibleChapters[i]),
              ),
            ),

          // ── See all / Show less button ────────────────────────────
          if (hasMore) ...[
            const SizedBox(height: AppSizes.sm),
            const Divider(height: 1, thickness: 0.5),
            InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _expanded
                          ? 'Show less'
                          : 'See all ${chapters.length} chapters',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
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
  const _ChapterRow({required this.stat});
  final ChapterStat stat;

  @override
  Widget build(BuildContext context) {
    final attempted = stat.score != null;
    final pct = (stat.score ?? 0.0).clamp(0.0, 100.0);

    Color barColor = AppColors.primary;
    if (pct < 50) barColor = AppColors.error;
    else if (pct < 70) barColor = AppColors.warning;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                stat.title,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            attempted
                ? Text(
                    '${pct.toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: barColor,
                    ),
                  )
                : const Text(
                    '—',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 13),
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
              backgroundColor: barColor.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),
        ],
      ],
    );
  }
}
