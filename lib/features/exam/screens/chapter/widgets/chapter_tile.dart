import 'package:flutter/material.dart';
import 'package:matricmate/features/exam/models/chapter_progress_model.dart';
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
    this.progress,
  });

  final String chapter, chapterTitle;
  final VoidCallback onTap;
  final bool hasSubTitle;
  final int? chapterNumber;
  final bool isSection;
  final ChapterProgressModel? progress;

  @override
  Widget build(BuildContext context) {
    final dark = AppHelperFunctions.isDark(context);
    final isCompleted = progress?.isCompleted ?? false;
    final hasTests = progress?.hasTests ?? true;
    final totalTests = progress?.totalTests ?? 0;
    final completedTests = progress?.completedTests ?? 0;
    final inProgressTests = progress?.inProgressTests ?? 0;

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
          color: isCompleted
              ? AppColors.success.withValues(alpha: dark ? 0.35 : 0.25)
              : (dark ? AppColors.darkBorder : AppColors.borderPrimary),
          width: isCompleted ? 1.3 : 1.0,
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
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? AppColors.success.withValues(
                            alpha: dark ? 0.20 : 0.12,
                          )
                        : AppColors.primary.withValues(
                            alpha: dark ? 0.18 : 0.10,
                          ),
                    borderRadius: BorderRadius.circular(15),
                    border: isCompleted
                        ? Border.all(
                            color: AppColors.success.withValues(alpha: 0.4),
                            width: 1,
                          )
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        isSection ? 'SEC' : 'CH',
                        style: TextStyle(
                          fontSize: 8.0,
                          fontWeight: FontWeight.w800,
                          color: isCompleted
                              ? AppColors.success
                              : AppColors.primary,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        badgeText,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                          color: isCompleted
                              ? AppColors.success
                              : (dark
                                  ? AppColors.textWhite
                                  : AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 14),

                // ── Chapter Title, Subtitle, & Uniform Progress Bar ──────────
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
                        totalTests > 0
                            ? '$chapter • $totalTests ${totalTests == 1 ? "Test" : "Tests"}'
                            : chapter,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: dark
                              ? AppColors.darkGrey
                              : AppColors.textSecondary,
                        ),
                      ),

                      // Equal-length progress bar (Completed + In-Progress + Not-Started) with numbers only
                      if (totalTests > 0) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: Container(
                                  height: 5,
                                  color: dark
                                      ? const Color(0xFF2A2A2A)
                                      : const Color(0xFFE5E7EB),
                                  child: LayoutBuilder(
                                    builder: (context, constraints) {
                                      final totalWidth = constraints.maxWidth;
                                      final completedWidth =
                                          ((completedTests / totalTests) *
                                                  totalWidth)
                                              .clamp(0.0, totalWidth);
                                      final inProgWidth =
                                          ((inProgressTests / totalTests) *
                                                  totalWidth)
                                              .clamp(
                                                  0.0,
                                                  totalWidth - completedWidth);

                                      return Row(
                                        children: [
                                          if (completedWidth > 0)
                                            Container(
                                              width: completedWidth,
                                              height: 5,
                                              color: isCompleted
                                                  ? AppColors.success
                                                  : AppColors.primary,
                                            ),
                                          if (inProgWidth > 0)
                                            Container(
                                              width: inProgWidth,
                                              height: 5,
                                              color: const Color(0xFF3B82F6),
                                            ),
                                        ],
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            SizedBox(
                              width: 36,
                              child: Text(
                                '$completedTests/$totalTests',
                                textAlign: TextAlign.end,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: isCompleted
                                      ? AppColors.success
                                      : (dark
                                          ? AppColors.darkGrey
                                          : AppColors.textSecondary),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // ── Trailing Chevron or Soon Pill ────────────────────────────
                if (!hasTests)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: dark
                          ? AppColors.darkSurface
                          : AppColors.lightGrey,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Soon',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: dark
                            ? AppColors.darkGrey
                            : AppColors.textSecondary,
                      ),
                    ),
                  )
                else
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 22,
                    color: isCompleted
                        ? AppColors.success
                        : (dark ? AppColors.darkGrey : AppColors.grey),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
