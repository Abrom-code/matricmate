import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matricmate/features/challenges/controllers/challenge_home_controller.dart';
import 'package:matricmate/features/challenges/models/challenge_model.dart';
import 'package:matricmate/features/challenges/screens/leaderboard_screen.dart';
import 'package:matricmate/utils/constants/colors.dart';

/// Redesigned Available Challenge Card for Upcoming and Live rounds.
class AvailableChallengeCard extends StatelessWidget {
  const AvailableChallengeCard({
    super.key,
    required this.challenge,
    required this.ctrl,
    required this.dark,
  });

  final LeaderboardChallengeModel challenge;
  final ChallengeHomeController ctrl;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // Subscribe to real-time timer ticker
      final _ = ctrl.now.value;
      final isLive = challenge.isLive;

      // Countdown calculations
      final targetTime = isLive
          ? (challenge.endsAt ?? challenge.startsAt)
          : challenge.startsAt;

      String hours = '00';
      String minutes = '00';
      String seconds = '00';

      if (targetTime != null) {
        final diff = targetTime.difference(ctrl.now.value);
        final totalSec = diff.isNegative ? 0 : diff.inSeconds;
        hours = (totalSec ~/ 3600).toString().padLeft(2, '0');
        minutes = ((totalSec % 3600) ~/ 60).toString().padLeft(2, '0');
        seconds = (totalSec % 60).toString().padLeft(2, '0');
      }

      final durationMins = challenge.durationMinutes > 0
          ? challenge.durationMinutes
          : (challenge.durationSeconds / 60).round();

      final isDone = ctrl.isAttemptedOrPracticed(challenge.id) ||
          ctrl.completedChallenges.any((c) =>
              c.id == challenge.id ||
              (challenge.setId.isNotEmpty && c.setId == challenge.setId));

      return Container(
        decoration: BoxDecoration(
          color: dark ? AppColors.darkCard : AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: dark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: dark
                  ? Colors.black.withValues(alpha: 0.28)
                  : const Color(0xFF64748B).withValues(alpha: 0.07),
              blurRadius: 14,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── 1. Header Row (Subject Chip & Status Indicator) ─────────
            Row(
              children: [
                // Subject Chip (Uniform teal style, no icon)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.teal.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    challenge.subjectName ?? 'Challenge',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.teal,
                    ),
                  ),
                ),

                const Spacer(),

                // Status Indicator (No container, icon + text)
                if (isLive) ...[
                  const Icon(
                    Icons.circle,
                    size: 8,
                    color: Color(0xFFE24B4A),
                  ),
                  const SizedBox(width: 5),
                  const Text(
                    'Live',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFE24B4A),
                    ),
                  ),
                ] else ...[
                  const Icon(
                    Icons.access_time_rounded,
                    size: 13,
                    color: Color(0xFF378ADD),
                  ),
                  const SizedBox(width: 5),
                  const Text(
                    'Upcoming',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF378ADD),
                    ),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 16),

            // ── 2. Title ────────────────────────────────────────────────
            Text(
              challenge.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: dark ? Colors.white : AppColors.textPrimary,
                height: 1.25,
              ),
            ),

            const SizedBox(height: 12),

            // ── 3. Meta Row (Time on left, Number of joins on right) ──────
            Row(
              children: [
                // Duration / Time it takes (left)
                const Icon(
                  Icons.access_time_rounded,
                  size: 15,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 5),
                Text(
                  '$durationMins mins',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const Spacer(),

                // Number of joins (right)
                const Icon(
                  Icons.people_outline_rounded,
                  size: 15,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 5),
                Text(
                  '${ctrl.getParticipantCount(challenge.id)} joined',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ── 4. Countdown Row (Single Line) ──────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              decoration: BoxDecoration(
                color: dark
                    ? Colors.white.withValues(alpha: 0.04)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isLive ? 'Ends in ' : 'Starts in ',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$hours:$minutes:$seconds',
                    style: TextStyle(
                      color: dark ? Colors.white : AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      fontFeatures: const [FontFeature.tabularFigures()],
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── 5. Action Button ────────────────────────────────────────
            if (isLive) ...[
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.teal,
                    foregroundColor: const Color(0xFF04342C),
                    elevation: 0,
                    padding: EdgeInsets.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: isDone
                      ? () => ctrl.openCompletedChallenge(challenge)
                      : () => ctrl.onChallengeTapped(challenge),
                  icon: Icon(
                    isDone
                        ? Icons.visibility_outlined
                        : Icons.arrow_forward_rounded,
                    size: 16,
                    color: const Color(0xFF04342C),
                  ),
                  label: Text(
                    isDone ? 'Review' : 'Start challenge',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF04342C),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: InkWell(
                  borderRadius: BorderRadius.circular(6),
                  onTap: () => Get.to(
                    () => LeaderboardScreen(
                      challengeId: challenge.id,
                      challengeTitle: challenge.title,
                      audience: challenge.audience,
                    ),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                    child: Text(
                      'View rankings →',
                      style: TextStyle(
                        color: AppColors.amber,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            ] else ...[
              SizedBox(
                width: double.infinity,
                height: 46,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    backgroundColor: const Color(0x26378ADD),
                    foregroundColor: const Color(0xFF85B7EB),
                    side: const BorderSide(
                      color: Color(0x66378ADD),
                      width: 1,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                    padding: EdgeInsets.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () => ctrl.onChallengeTapped(challenge),
                  icon: const Icon(
                    Icons.notifications_outlined,
                    size: 16,
                    color: Color(0xFF85B7EB),
                  ),
                  label: const Text(
                    'Scheduled',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF85B7EB),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    });
  }
}
