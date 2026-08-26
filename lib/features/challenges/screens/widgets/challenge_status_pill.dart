import 'package:flutter/material.dart';
import 'package:matricmate/features/challenges/constants/challenge_colors.dart';
import 'package:matricmate/features/challenges/models/challenge_model.dart';
import 'package:matricmate/utils/constants/colors.dart';

class ChallengeStatusPill extends StatelessWidget {
  const ChallengeStatusPill({
    super.key,
    required this.challenge,
    required this.dark,
  });

  final LeaderboardChallengeModel challenge;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    if (challenge.isLive) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: ChallengeColors.live.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.circle, size: 7, color: ChallengeColors.live),
            SizedBox(width: 4),
            Text(
              'LIVE',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: ChallengeColors.live,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      );
    }

    if (challenge.isScheduled) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: ChallengeColors.scheduled.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Text(
          'UPCOMING',
          style: TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w700,
            color: ChallengeColors.scheduled,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: dark ? Colors.white12 : const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        'CLOSED',
        style: TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
          color: dark ? Colors.white70 : AppColors.textSecondary,
        ),
      ),
    );
  }
}
