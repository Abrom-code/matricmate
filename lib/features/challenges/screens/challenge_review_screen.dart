import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:matricmate/data/repositories/challenge/challenge_repository.dart';
import 'package:matricmate/features/challenges/constants/challenge_colors.dart';
import 'package:matricmate/features/challenges/controllers/challenge_home_controller.dart';
import 'package:matricmate/features/challenges/models/challenge_leaderboard_entry.dart';
import 'package:matricmate/features/challenges/models/challenge_question_model.dart';
import 'package:matricmate/features/challenges/screens/challenge_attempt_screen.dart';
import 'package:matricmate/features/challenges/screens/widgets/challenge_question_box.dart';
import 'package:matricmate/features/challenges/screens/widgets/review_stat_badge.dart';
import 'package:matricmate/features/personalization/controllers/user_controller.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/constants/sizes.dart';
import 'package:matricmate/utils/helpers/challenge_access_helper.dart';
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
    this.isRedo = false,
    this.isLive = false,
  });

  final String title;
  final List<ChallengeQuestionModel> questions;
  final Map<String, String> userAnswers;
  final int? score;
  final int? timeSpentSeconds;
  final String? challengeId;
  final String? audience;
  final bool isRedo;
  final bool isLive;

  @override
  State<ChallengeReviewScreen> createState() => _ChallengeReviewScreenState();
}

class _ChallengeReviewScreenState extends State<ChallengeReviewScreen> {
  final _scrollCtrl = ScrollController();
  late List<ChallengeQuestionModel> _reviewQuestions;
  ChallengeLeaderboardEntry? _userStanding;
  bool _isLoadingStanding = false;

  bool get _isLive {
    if (widget.isLive) return true;
    if (widget.challengeId != null && Get.isRegistered<ChallengeHomeController>()) {
      return ChallengeHomeController.instance.availableChallenges
          .any((c) => c.id == widget.challengeId && c.isLive);
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    _reviewQuestions = List.from(widget.questions);
    _loadPassagesIfNeeded();
    if (widget.challengeId != null && _isLive) {
      _loadStanding();
    }
  }

  Future<void> _loadStanding() async {
    final uid = UserController.instance.user.value.id;
    if (uid.isEmpty || widget.challengeId == null) return;
    setState(() => _isLoadingStanding = true);
    try {
      final repo = ChallengeRepository();
      final standing = await repo.fetchUserChallengeStanding(
        challengeId: widget.challengeId!,
        userId: uid,
        stream: widget.audience,
      );
      if (mounted) {
        setState(() {
          _userStanding = standing;
          _isLoadingStanding = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingStanding = false);
    }
  }

  Future<void> _loadPassagesIfNeeded() async {
    final repo = ChallengeRepository();
    bool updated = false;
    final updatedList = <ChallengeQuestionModel>[];
    for (final q in _reviewQuestions) {
      if (q.passageId != null && q.passage == null) {
        final p = await repo.getPassage(q.passageId);
        if (p != null) {
          updatedList.add(q.copyWith(passage: p));
          updated = true;
          continue;
        }
      }
      updatedList.add(q);
    }
    if (updated && mounted) {
      setState(() {
        _reviewQuestions = updatedList;
      });
    }
  }

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
    for (final q in _reviewQuestions) {
      if (!(_isQuestionSkipped(q)) && _isQuestionCorrect(q)) {
        correctCount++;
      }
    }

    final total = _reviewQuestions.length;
    final accuracyPercent = total > 0
        ? ((correctCount / total) * 100).toStringAsFixed(0)
        : '0';

    String formattedTime = '--';
    if (widget.timeSpentSeconds != null && widget.timeSpentSeconds! > 0) {
      final m = widget.timeSpentSeconds! ~/ 60;
      final s = widget.timeSpentSeconds! % 60;
      formattedTime =
          '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
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
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // ── Top Summary Header Card (Time Taken, Score, Accuracy) ──
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.md,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: dark ? AppColors.darkCard : AppColors.white,
              border: Border(
                bottom: BorderSide(
                  color: dark ? AppColors.darkBorder : AppColors.borderPrimary,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: ReviewStatBadge(
                    label: 'Time Taken',
                    value: formattedTime,
                    color: ChallengeColors.accent,
                    icon: Iconsax.timer_1_copy,
                  ),
                ),
                Expanded(
                  child: ReviewStatBadge(
                    label: 'Score',
                    value: '$correctCount / $total',
                    color: AppColors.primary,
                    icon: Iconsax.award_copy,
                  ),
                ),
                Expanded(
                  child: ReviewStatBadge(
                    label: 'Accuracy',
                    value: '$accuracyPercent%',
                    color: ChallengeColors.completed,
                    icon: Iconsax.chart_2_copy,
                  ),
                ),
              ],
            ),
          ),

          // ── Live Standing Card (When Challenge is Live) ──────────
          if (widget.challengeId != null && _isLive)
            _buildLiveStandingCard(dark),

          // ── Questions Review List ────────────────────────────────
          Expanded(
            child: _reviewQuestions.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSizes.xl),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Iconsax.document_copy,
                            size: 44,
                            color: dark
                                ? Colors.white24
                                : AppColors.textSecondary,
                          ),
                          const SizedBox(height: AppSizes.md),
                          const Text(
                            'No questions available for review',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.all(AppSizes.md),
                    itemCount: _reviewQuestions.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSizes.spaceBtwItems),
                    itemBuilder: (context, index) {
                      final question = _reviewQuestions[index];
                      final userAnswer = widget.userAnswers[question.id];

                      return ChallengeQuestionBox(
                        question: question,
                        orderIndex: index + 1,
                        totalQuestions: _reviewQuestions.length,
                        selectedChoice: userAnswer,
                        isChecked: true,
                        showExplanation: true,
                        initialExplanationExpanded: false,
                        showInlinePassage: true,
                      );
                    },
                  ),
          ),

          // ── Bottom Action Button (Redo / Standings / Done) ────────────────
          if (widget.challengeId != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: 12),
              decoration: BoxDecoration(
                color: dark ? AppColors.darkCard : AppColors.white,
                border: Border(
                  top: BorderSide(
                    color: dark
                        ? AppColors.darkBorder
                        : AppColors.borderPrimary,
                  ),
                ),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () => Get.back(),
                            child: const Text(
                              'Done',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13.5,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        if (_isLive)
                          Expanded(
                            flex: 2,
                            child: FilledButton.icon(
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () => ChallengeAccessHelper.openLeaderboard(
                                challengeId: widget.challengeId,
                                challengeTitle: widget.title,
                                audience: widget.audience,
                                userScore: widget.score ?? _userStanding?.score,
                                userTimeSeconds: widget.timeSpentSeconds ?? _userStanding?.totalTimeSeconds,
                              ),
                              icon: const Icon(Icons.leaderboard_rounded, size: 18),
                              label: const Text(
                                'View Standings',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13.5,
                                ),
                              ),
                            ),
                          )
                        else
                          Expanded(
                            child: FilledButton.icon(
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                backgroundColor: AppColors.teal,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () => Get.off(
                                () => ChallengeAttemptScreen(
                                  challengeId: widget.challengeId!,
                                  title: widget.title,
                                  audience: widget.audience,
                                  isRedo: true,
                                ),
                              ),
                              icon: const Icon(Icons.replay_rounded, size: 18),
                              label: Text(
                                widget.isRedo ? 'Redo Again' : 'Redo Challenge',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13.5,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (_isLive) ...[
                      const SizedBox(height: 6),
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          foregroundColor:
                              dark ? Colors.white70 : AppColors.textSecondary,
                        ),
                        onPressed: () => Get.off(
                          () => ChallengeAttemptScreen(
                            challengeId: widget.challengeId!,
                            title: widget.title,
                            audience: widget.audience,
                            isRedo: true,
                          ),
                        ),
                        icon: const Icon(Icons.replay_rounded, size: 15),
                        label: const Text(
                          'Practice / Redo Challenge',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLiveStandingCard(bool dark) {
    final entry = _userStanding;
    final int? userRank = entry?.rank;
    final int? userScore = widget.score ?? entry?.score;
    final String userTime = (widget.timeSpentSeconds != null && widget.timeSpentSeconds! > 0)
        ? '${(widget.timeSpentSeconds! ~/ 60).toString().padLeft(2, '0')}:${(widget.timeSpentSeconds! % 60).toString().padLeft(2, '0')}'
        : (entry?.formattedTime ?? '--');

    return Container(
      margin: const EdgeInsets.fromLTRB(AppSizes.md, AppSizes.sm, AppSizes.md, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: dark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: dark ? AppColors.darkBorder : AppColors.borderPrimary,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.emoji_events_rounded,
                  size: 16,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'LIVE STANDING',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: () => ChallengeAccessHelper.openLeaderboard(
                  challengeId: widget.challengeId,
                  challengeTitle: widget.title,
                  audience: widget.audience,
                  userScore: userScore,
                  userTimeSeconds:
                      widget.timeSpentSeconds ?? entry?.totalTimeSeconds,
                ),
                borderRadius: BorderRadius.circular(6),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Full Board',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                      SizedBox(width: 2),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 16,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (_isLoadingStanding)
            Row(
              children: [
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 10),
                Text(
                  'Calculating your live rank on the leaderboard...',
                  style: TextStyle(
                    fontSize: 12,
                    color: dark ? Colors.white70 : AppColors.textSecondary,
                  ),
                ),
              ],
            )
          else if (userRank != null)
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: userRank == 1
                          ? [const Color(0xFFFFD700), const Color(0xFFFFA500)]
                          : userRank == 2
                              ? [const Color(0xFFC0C0C0), const Color(0xFF9E9E9E)]
                              : userRank == 3
                                  ? [
                                      const Color(0xFFCD7F32),
                                      const Color(0xFF8D5524),
                                    ]
                                  : [
                                      AppColors.primary,
                                      AppColors.primary.withValues(alpha: 0.8),
                                    ],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'RANK',
                        style: TextStyle(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        '#$userRank',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          height: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userRank <= 3
                            ? 'Top 3 Podium Placement!'
                            : userRank <= 10
                                ? 'Top 10 Contender!'
                                : 'Live Challenge Submitted',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Score: ${userScore ?? 0} pts  •  Time: $userTime',
                        style: TextStyle(
                          fontSize: 11.5,
                          color:
                              dark ? Colors.white70 : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Your attempt is recorded. Check live leaderboard for rankings.',
                    style: TextStyle(
                      fontSize: 12,
                      color: dark ? Colors.white70 : AppColors.textSecondary,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _loadStanding,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  tooltip: 'Reload standing',
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
        ],
      ),
    );
  }
}
