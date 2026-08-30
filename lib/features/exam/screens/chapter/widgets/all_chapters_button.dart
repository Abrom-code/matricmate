import 'package:flutter/material.dart';
import 'package:matricmate/features/exam/models/chapter_progress_model.dart';
import 'package:matricmate/utils/constants/colors.dart';

class AllChaptersButton extends StatelessWidget {
  const AllChaptersButton({
    super.key,
    required this.onPressed,
    this.progress,
  });

  final VoidCallback onPressed;
  final ChapterProgressModel? progress;

  @override
  Widget build(BuildContext context) {
    final hasTests = progress?.hasTests ?? false;
    final totalTests = progress?.totalTests ?? 0;
    final completedTests = progress?.completedTests ?? 0;
    final inProgressTests = progress?.inProgressTests ?? 0;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFF00796B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                // ── Left Icon Squircle ──────────────────────────────
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.layers_rounded,
                    color: AppColors.white,
                    size: 22,
                  ),
                ),

                const SizedBox(width: 14),

                // ── Title, Subtitle, & Uniform Progress Bar ──────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Practice All Chapters',
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.white,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        hasTests
                            ? '$totalTests ${totalTests == 1 ? "Combined Test" : "Combined Tests"} • Comprehensive Practice'
                            : 'Comprehensive grade-level exam practice',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),

                      // Equal-length progress bar (Completed + In-Progress + Not-Started) with numbers only
                      if (hasTests) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: Container(
                                  height: 5,
                                  color: Colors.white.withValues(alpha: 0.25),
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
                                              color: Colors.white,
                                            ),
                                          if (inProgWidth > 0)
                                            Container(
                                              width: inProgWidth,
                                              height: 5,
                                              color: const Color(0xFF67E8F9),
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
                                  color: Colors.white.withValues(alpha: 0.95),
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

                // ── Trailing Chevron ─────────────────────────────────
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.white,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
