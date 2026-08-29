import 'package:flutter/material.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

class ChapterTile extends StatelessWidget {
  const ChapterTile({
    super.key,
    required this.chapter,
    required this.chapterTitle,
    required this.onTap,
    this.hasSubTitle = true,
    this.chapterNumber,
    this.isSection = false,
  });

  final String chapter, chapterTitle;
  final VoidCallback onTap;
  final bool hasSubTitle;
  final int? chapterNumber;
  final bool isSection;

  @override
  Widget build(BuildContext context) {
    final dark = AppHelperFunctions.isDark(context);

    // Extract chapter number badge string, e.g. "01"
    String badgeText = isSection ? '01' : 'CH';
    if (chapterNumber != null) {
      badgeText = chapterNumber! < 10 ? '0$chapterNumber' : '$chapterNumber';
    } else {
      final numMatch = RegExp(r'\b\d+\b').firstMatch(chapter);
      if (numMatch != null) {
        final n = int.tryParse(numMatch.group(0)!);
        if (n != null) badgeText = n < 10 ? '0$n' : '$n';
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: dark ? AppColors.darkCard : AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: dark ? AppColors.darkBorder : AppColors.borderPrimary,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? 0.25 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                // ── Left Chapter / Section Squircle Badge ─────────────────────
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(
                      alpha: dark ? 0.18 : 0.10,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        isSection ? 'SEC' : 'CH',
                        style: const TextStyle(
                          fontSize: 8.0,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        badgeText,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                          color: dark
                              ? AppColors.textWhite
                              : AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 14),

                // ── Chapter Title & Subtitle ────────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        chapterTitle,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                          color: dark
                              ? AppColors.textWhite
                              : AppColors.textPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        chapter,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: dark
                              ? AppColors.darkGrey
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // ── Trailing Chevron ────────────────────────────────
                Icon(
                  Icons.chevron_right_rounded,
                  size: 22,
                  color: dark ? AppColors.darkGrey : AppColors.grey,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
