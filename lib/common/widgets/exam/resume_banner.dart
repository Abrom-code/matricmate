import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matricmate/features/exam/models/result_model.dart';
import 'package:matricmate/features/exam/screens/ready/ready.dart';
import 'package:matricmate/utils/constants/sizes.dart';

/// A reusable "resume in-progress test" banner.
///
/// Tapping it opens the [ReadyDialog] so the user can resume their paused test.
class ResumeBanner extends StatelessWidget {
  const ResumeBanner({
    super.key,
    required this.testTitle,
    required this.answered,
    required this.total,
    required this.draft,
    required this.testTime,
  });

  final String testTitle;
  final int answered;
  final int total;
  final ResultModel draft;
  final int testTime;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final progress = total > 0 ? answered / total : 0.0;
    final pct = (progress * 100).round();

    const accentColor = Colors.indigo;

    return Material(
      color: cs.surfaceContainerHighest.withValues(alpha: 0.55),
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Get.dialog(
          ReadyDialog(
            qnCount: total,
            time: testTime,
            testId: draft.testId,
            id: -1,
            draft: draft,
          ),
        ),
        child: Row(
          children: [
            // Left accent stripe
            Container(width: 4, height: 72, color: accentColor),

            const SizedBox(width: 14),

            // Pause icon
            const Icon(
              Icons.pause_circle_filled_rounded,
              color: accentColor,
              size: 28,
            ),

            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Label + percentage row
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'IN PROGRESS',
                            style: tt.labelSmall?.copyWith(
                              color: accentColor,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.6,
                              fontSize: 9,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '$pct%',
                          style: tt.labelSmall?.copyWith(
                            color: accentColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),

                    // Test title
                    Text(
                      testTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: tt.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Progress bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress.clamp(0.0, 1.0),
                        minHeight: 4,
                        backgroundColor: accentColor.withValues(alpha: 0.15),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          accentColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),

                    Text(
                      '$answered of $total questions answered',
                      style: tt.labelSmall?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.sm,
              ),
              child: Icon(
                Icons.chevron_right_rounded,
                color: cs.onSurface.withValues(alpha: 0.35),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
