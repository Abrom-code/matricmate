import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:matricmate/features/challenges/models/challenge_question_model.dart';
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
  });

  final String title;
  final List<ChallengeQuestionModel> questions;
  final Map<String, String> userAnswers;
  final int? score;
  final int? timeSpentSeconds;
  final String? challengeId;

  @override
  State<ChallengeReviewScreen> createState() => _ChallengeReviewScreenState();
}

class _ChallengeReviewScreenState extends State<ChallengeReviewScreen> {
  final _scrollCtrl = ScrollController();
  final _filter = 'all'.obs; // 'all', 'correct', 'incorrect', 'skipped'

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

    // Compute stats
    int correctCount = 0;
    int skippedCount = 0;
    int wrongCount = 0;

    for (final q in widget.questions) {
      if (_isQuestionSkipped(q)) {
        skippedCount++;
      } else if (_isQuestionCorrect(q)) {
        correctCount++;
      } else {
        wrongCount++;
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
      appBar: AppBar(
        title: Text(
          'Review: ${widget.title}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        actions: [
          if (widget.challengeId != null)
            TextButton.icon(
              onPressed: () => Get.to(
                () => LeaderboardScreen(
                  challengeId: widget.challengeId,
                  challengeTitle: widget.title,
                  userScore: correctCount,
                  userTimeSeconds: widget.timeSpentSeconds,
                ),
              ),
              icon: const Icon(Iconsax.ranking_copy, size: 15),
              label: const Text('Leaderboard', style: TextStyle(fontSize: 12)),
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // ── Top Summary Header Card ──────────────────────────────
          Container(
            padding: const EdgeInsets.all(AppSizes.md),
            decoration: BoxDecoration(
              color: dark ? AppColors.darkCard : AppColors.white,
              border: Border(
                bottom: BorderSide(
                  color: dark ? AppColors.darkBorder : AppColors.borderPrimary,
                ),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
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
                    _StatBadge(
                      label: 'Time Taken',
                      value: formattedTime,
                      color: const Color(0xFF8B5CF6),
                      icon: Iconsax.timer_1_copy,
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Filter tabs
                Obx(() => SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _FilterChip(
                            label: 'All ($total)',
                            selected: _filter.value == 'all',
                            onTap: () => _filter.value = 'all',
                          ),
                          const SizedBox(width: 8),
                          _FilterChip(
                            label: 'Correct ($correctCount)',
                            color: const Color(0xFF10B981),
                            selected: _filter.value == 'correct',
                            onTap: () => _filter.value = 'correct',
                          ),
                          const SizedBox(width: 8),
                          _FilterChip(
                            label: 'Wrong ($wrongCount)',
                            color: const Color(0xFFEF4444),
                            selected: _filter.value == 'incorrect',
                            onTap: () => _filter.value = 'incorrect',
                          ),
                          if (skippedCount > 0) ...[
                            const SizedBox(width: 8),
                            _FilterChip(
                              label: 'Skipped ($skippedCount)',
                              color: const Color(0xFFF59E0B),
                              selected: _filter.value == 'skipped',
                              onTap: () => _filter.value = 'skipped',
                            ),
                          ],
                        ],
                      ),
                    )),
              ],
            ),
          ),

          // ── Questions Review List ────────────────────────────────
          Expanded(
            child: Obx(() {
              final activeFilter = _filter.value;
              final filteredQuestions = widget.questions.where((q) {
                if (activeFilter == 'correct') return _isQuestionCorrect(q);
                if (activeFilter == 'incorrect') return !_isQuestionCorrect(q) && !_isQuestionSkipped(q);
                if (activeFilter == 'skipped') return _isQuestionSkipped(q);
                return true;
              }).toList();

              if (filteredQuestions.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSizes.xl),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Iconsax.document_copy, size: 44, color: dark ? Colors.white24 : AppColors.textSecondary),
                        const SizedBox(height: AppSizes.md),
                        Text(
                          'No questions in "$activeFilter" category',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return Scrollbar(
                controller: _scrollCtrl,
                child: ListView.separated(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.all(AppSizes.md),
                  itemCount: filteredQuestions.length,
                  separatorBuilder: (_, __) => const SizedBox(height: AppSizes.spaceBtwItems),
                  itemBuilder: (context, idx) {
                    final q = filteredQuestions[idx];
                    final realOrderIndex = widget.questions.indexOf(q) + 1;
                    final selected = widget.userAnswers[q.id];

                    return ChallengeQuestionBox(
                      question: q,
                      orderIndex: realOrderIndex,
                      totalQuestions: total,
                      selectedChoice: selected,
                      isChecked: true,
                      showExplanation: true,
                      initialExplanationExpanded: true,
                    );
                  },
                ),
              );
            }),
          ),

          // ── Bottom Leaderboard Button ────────────────────────────
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
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () => Get.to(
                    () => LeaderboardScreen(
                      challengeId: widget.challengeId,
                      challengeTitle: widget.title,
                      userScore: correctCount,
                      userTimeSeconds: widget.timeSpentSeconds,
                    ),
                  ),
                  icon: const Icon(Iconsax.ranking_copy, size: 18),
                  label: const Text(
                    'View National Standings & Rankings',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
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

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.color,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final activeColor = color ?? AppColors.primary;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? activeColor.withValues(alpha: 0.16) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? activeColor : AppColors.borderPrimary,
            width: selected ? 1.4 : 1.0,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: selected ? FontWeight.bold : FontWeight.w500,
            color: selected ? activeColor : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
