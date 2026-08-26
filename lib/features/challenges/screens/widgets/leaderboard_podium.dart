import 'package:flutter/material.dart';
import 'package:matricmate/features/challenges/constants/challenge_colors.dart';
import 'package:matricmate/features/challenges/models/challenge_leaderboard_entry.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/constants/sizes.dart';

class LeaderboardPodium extends StatelessWidget {
  const LeaderboardPodium({
    super.key,
    required this.top3,
    required this.dark,
  });

  final List<ChallengeLeaderboardEntry> top3;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final first = top3.isNotEmpty ? top3[0] : null;
    final second = top3.length > 1 ? top3[1] : null;
    final third = top3.length > 2 ? top3[2] : null;

    return Column(
      children: [
        // ── Top Podium Header Perk Banner ──────────────────────────────────
        Container(
          margin: const EdgeInsets.only(bottom: AppSizes.md),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: ChallengeColors.gold.withValues(alpha: dark ? 0.15 : 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: ChallengeColors.gold.withValues(alpha: 0.3),
            ),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.emoji_events_rounded, size: 16, color: ChallengeColors.gold),
              SizedBox(width: 6),
              Flexible(
                child: Text(
                  'Top 3 Finishers claim Gold, Silver & Bronze Standings',
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: ChallengeColors.gold,
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── 3-Step Podium ───────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.xs),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // #2 Silver
              Expanded(
                child: second != null
                    ? _PodiumStep(
                        entry: second,
                        rank: 2,
                        height: 115,
                        color: ChallengeColors.silver,
                        badgeIcon: Icons.workspace_premium_rounded,
                        dark: dark,
                      )
                    : const SizedBox.shrink(),
              ),
              const SizedBox(width: 8),

              // #1 Gold
              Expanded(
                child: first != null
                    ? _PodiumStep(
                        entry: first,
                        rank: 1,
                        height: 145,
                        color: ChallengeColors.gold,
                        badgeIcon: Icons.emoji_events_rounded,
                        dark: dark,
                      )
                    : const SizedBox.shrink(),
              ),
              const SizedBox(width: 8),

              // #3 Bronze
              Expanded(
                child: third != null
                    ? _PodiumStep(
                        entry: third,
                        rank: 3,
                        height: 95,
                        color: ChallengeColors.bronze,
                        badgeIcon: Icons.military_tech_rounded,
                        dark: dark,
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PodiumStep extends StatelessWidget {
  const _PodiumStep({
    required this.entry,
    required this.rank,
    required this.height,
    required this.color,
    required this.badgeIcon,
    required this.dark,
  });

  final ChallengeLeaderboardEntry entry;
  final int rank;
  final double height;
  final Color color;
  final IconData badgeIcon;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Trophy Badge
        Icon(badgeIcon, size: rank == 1 ? 26 : 22, color: color),
        const SizedBox(height: 2),

        // Avatar circle
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              width: rank == 1 ? 54 : 48,
              height: rank == 1 ? 54 : 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    color.withValues(alpha: 0.3),
                    color.withValues(alpha: 0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: color, width: rank == 1 ? 2.5 : 2),
                boxShadow: rank == 1
                    ? [
                        BoxShadow(
                          color: color.withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: Text(
                  entry.fullName.isNotEmpty
                      ? entry.fullName[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    fontSize: rank == 1 ? 20 : 18,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(2.5),
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
              child: Text(
                '#$rank',
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),

        // Name
        Text(
          entry.fullName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: rank == 1 ? 12 : 11,
          ),
        ),
        const SizedBox(height: 2),

        // Score
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '${entry.score} pts',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 6),

        // Step Pillar
        Container(
          height: height,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color.withValues(alpha: dark ? 0.22 : 0.16),
                color.withValues(alpha: dark ? 0.08 : 0.05),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
            border: Border.all(color: color.withValues(alpha: 0.35)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '#$rank',
                style: TextStyle(
                  fontSize: rank == 1 ? 26 : 22,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                entry.formattedTime,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: dark ? Colors.white70 : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
