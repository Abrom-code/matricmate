import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:matricmate/features/challenges/models/challenge_question_model.dart';
import 'package:matricmate/features/challenges/screens/challenge_practice_screen.dart';
import 'package:matricmate/features/challenges/screens/leaderboard_screen.dart';
import 'package:matricmate/features/challenges/screens/widgets/challenge_question_box.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/constants/sizes.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

class ChallengeReviewScreen extends StatefulWidget {
  const ChallengeReviewScreen({
    super.key,
    required this.title,
    required this.questions,
    required this.userAnswers,
    this.score,
    this.timeSpentSeconds,
    this.challengeId,
    this.audience,
  });

  final String title;
  final List<ChallengeQuestionModel> questions;
  final Map<String, String> userAnswers;
  final int? score;
  final int? timeSpentSeconds;
  final String? challengeId;
  final String? audience;

  @override
  State<ChallengeReviewScreen> createState() => _ChallengeReviewScreenState();
}

class _ChallengeReviewScreenState extends State<ChallengeReviewScreen> {
  final _scrollCtrl = ScrollController();

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  bool _isQuestionCorrect(ChallengeQuestionModel q) {
    final ans = widget.userAnswers[q.id];
    if (ans == null || ans.isEmpty) return false;

    final parsedIdx = int.tryParse(q.correctChoice);
    if (parsedIdx != null && parsedIdx >= 0 && parsedIdx < q.choices.length) {
      final sIdx = int.tryParse(ans);
      if (sIdx == parsedIdx) return true;
      if (ans == q.choices[parsedIdx]) return true;
    }
    return ans == q.correctChoice;
  }

  bool _isQuestionSkipped(ChallengeQuestionModel q) {
    final ans = widget.userAnswers[q.id];
    return ans == null || ans.isEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final dark = AppHelperFunctions.isDark(context);

    // Compute statistics
    int correctCount = 0;
    for (final q in widget.questions) {
      if (!(_isQuestionSkipped(q)) && _isQuestionCorrect(q)) {
        correctCount++;
      }
    }

    final total = widget.questions.length;
    final accuracyPercent = total > 0 ? ((correctCount / total) * 100).toStringAsFixed(0) : '0';

    String formattedTime = '--';
    if (widget.timeSpentSeconds != null && widget.timeSpentSeconds! > 0) {
      final m = widget.timeSpentSeconds! ~/ 60;
      final s = widget.timeSpentSeconds! % 60;
      formattedTime = '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }

    return Scaffold(
      backgroundColor: dark ? AppColors.dark : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Challenge Review',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            Text(
              widget.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.normal),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // ── Top Summary Header Card (Time Taken, Score, Accuracy) ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: 12),
            decoration: BoxDecoration(
              color: dark ? AppColors.darkCard : AppColors.white,
              border: Border(
                bottom: BorderSide(
                  color: dark ? AppColors.darkBorder : AppColors.borderPrimary,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatBadge(
                  label: 'Time Taken',
                  value: formattedTime,
                  color: const Color(0xFF8B5CF6),
                  icon: Iconsax.timer_1_copy,
                ),
                _StatBadge(
                  label: 'Score',
                  value: '$correctCount / $total',
                  color: AppColors.primary,
                  icon: Iconsax.award_copy,
                ),
                _StatBadge(
                  label: 'Accuracy',
                  value: '$accuracyPercent%',
                  color: const Color(0xFF10B981),
                  icon: Iconsax.chart_2_copy,
                ),
              ],
            ),
          ),

          // ── Questions Review List ────────────────────────────────
          Expanded(
            child: widget.questions.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSizes.xl),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Iconsax.document_copy, size: 44, color: dark ? Colors.white24 : AppColors.textSecondary),
                          const SizedBox(height: AppSizes.md),
                          const Text(
                            'No questions available for review',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  )
                : Scrollbar(
                    controller: _scrollCtrl,
                    child: ListView.separated(
                      controller: _scrollCtrl,
                      padding: const EdgeInsets.all(AppSizes.md),
                      itemCount: widget.questions.length,
                      separatorBuilder: (_, __) => const SizedBox(height: AppSizes.spaceBtwItems),
                      itemBuilder: (context, idx) {
                        final q = widget.questions[idx];
                        final selected = widget.userAnswers[q.id];

                        return ChallengeQuestionBox(
                          question: q,
                          orderIndex: idx + 1,
                          totalQuestions: total,
                          selectedChoice: selected,
                          isChecked: true,
                          showExplanation: true,
                          initialExplanationExpanded: false, // Closed by default, user can toggle open/close
                        );
                      },
                    ),
                  ),
          ),

          // ── Bottom Action Bar (Practice Again + Standings) ───────
          if (widget.challengeId != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: 12),
              decoration: BoxDecoration(
                color: dark ? AppColors.darkCard : AppColors.white,
                border: Border(
                  top: BorderSide(
                    color: dark ? AppColors.darkBorder : AppColors.borderPrimary,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(
                          color: dark ? AppColors.darkBorder : AppColors.borderPrimary,
                        ),
                      ),
                      onPressed: () => Get.to(
                        () => ChallengePracticeScreen(
                          challengeId: widget.challengeId!,
                          title: widget.title,
                        ),
                      ),
                      icon: const Icon(Icons.refresh_rounded, size: 16),
                      label: const Text('Practice Again', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () => Get.to(
                        () => LeaderboardScreen(
                          challengeId: widget.challengeId,
                          challengeTitle: widget.title,
                          audience: widget.audience,
                          userScore: correctCount,
                          userTimeSeconds: widget.timeSpentSeconds,
                        ),
                      ),
                      icon: const Icon(Iconsax.ranking_copy, size: 16),
                      label: const Text(
                        'Standings & Rankings',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  const _StatBadge({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String label;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14,
                color: color,
              ),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary),
            ),
          ],
        ),
      ],
    );
  }
}
