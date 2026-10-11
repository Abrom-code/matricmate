import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matricmate/features/challenges/controllers/challenge_home_controller.dart';
import 'package:matricmate/features/challenges/models/challenge_model.dart';
import 'package:matricmate/features/challenges/screens/leaderboard_screen.dart';
import 'package:matricmate/features/personalization/controllers/user_controller.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

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
      final canAccess = ctrl.canAccess(challenge);
      final isPending = UserController.instance.user.value.isPending;

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

      final isDone = ctrl.isChallengeCompleted(challenge);

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
                // Subject Chip
                Flexible(
                  child: Container(
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
                ),


                const Spacer(),

                if (isDone) ...[
                  // Double check completed icon
                  const Tooltip(
                    message: 'Completed',
                    child: Icon(
                      Icons.done_all_rounded,
                      size: 19,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],

                // Status Indicator (Live / Upcoming / Draft)
                if (challenge.isDraft) ...[
                  const Icon(Icons.build_circle_outlined, size: 14, color: Colors.amber),
                  const SizedBox(width: 5),
                  const Text(
                    'Draft Mode',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.amber,
                    ),
                  ),
                ] else if (isLive) ...[
                  const Icon(Icons.circle, size: 8, color: Color(0xFFE24B4A)),
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

            // ── 3. Meta Row ─────────────────────────────────────────────
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
            // If Free User and challenge is Premium: Show amber lock icon button
            if (!canAccess) ...[
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isPending
                        ? const Color(0xFFD97706)
                        : Colors.amber.shade700,
                    foregroundColor: Colors.white,
                    side: BorderSide(
                      color: isPending
                          ? const Color(0xFFD97706)
                          : Colors.amber.shade700,
                    ),
                    elevation: 0,
                    padding: EdgeInsets.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => ctrl.onChallengeTapped(challenge),
                  icon: Icon(
                    isPending ? Icons.hourglass_top_rounded : Icons.lock,
                    size: 16,
                    color: Colors.white,
                  ),
                  label: Text(
                    isPending ? 'Verifying' : 'Unlock (Pro)',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              if (isLive) ...[
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
                      padding: EdgeInsets.symmetric(
                        vertical: 2,
                        horizontal: 4,
                      ),
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
              ],
            ] else if (challenge.isDraft && UserController.instance.isAdmin.value) ...[
              // Admin draft verification: Side-by-side Preview + Publish buttons
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0284C7),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: EdgeInsets.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: () => ctrl.onChallengeTapped(challenge),
                        icon: const Icon(
                          Icons.visibility_outlined,
                          size: 16,
                          color: Colors.white,
                        ),
                        label: const Text(
                          'Preview',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SizedBox(
                      height: 44,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          backgroundColor: dark
                              ? const Color(0xFF10B981).withValues(alpha: 0.15)
                              : const Color(0xFFECFDF5),
                          foregroundColor: dark
                              ? const Color(0xFF34D399)
                              : const Color(0xFF059669),
                          side: BorderSide(
                            color: const Color(0xFF10B981).withValues(alpha: 0.5),
                            width: 1.2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                          padding: EdgeInsets.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: () {
                          AppHelperFunctions.showAppDialog(
                            context,
                            'Publish Challenge?',
                            'This challenge will be verified and published for students nationwide.',
                            () async {
                              Get.back();
                              await ctrl.verifyAndPublishChallenge(challenge.id);
                            },
                            okText: 'Publish Now',
                            cancelText: 'Cancel',
                            icon: Icons.verified_rounded,
                            iconColor: const Color(0xFF10B981),
                          );
                        },
                        icon: Icon(
                          Icons.verified_rounded,
                          size: 16,
                          color: dark
                              ? const Color(0xFF34D399)
                              : const Color(0xFF059669),
                        ),
                        label: Text(
                          'Publish Now',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: dark
                                ? const Color(0xFF34D399)
                                : const Color(0xFF059669),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (isLive) ...[
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
                      padding: EdgeInsets.symmetric(
                        vertical: 2,
                        horizontal: 4,
                      ),
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
              ],
            ] else if (isLive) ...[
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDone
                        ? AppColors.primary
                        : const Color(0xFF10B981),
                    foregroundColor: Colors.white,
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
                    color: Colors.white,
                  ),
                  label: Text(
                    isDone ? 'Review' : 'Start challenge',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
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
                    padding: EdgeInsets.symmetric(
                      vertical: 2,
                      horizontal: 4,
                    ),
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
                height: 44,
                child: UserController.instance.isAdmin.value
                    ? ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0284C7),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: EdgeInsets.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: () => ctrl.onChallengeTapped(challenge),
                        icon: const Icon(
                          Icons.visibility_outlined,
                          size: 16,
                          color: Colors.white,
                        ),
                        label: const Text(
                          'Preview Questions',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      )
                    : OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          backgroundColor: dark
                              ? const Color(0xFF0284C7).withValues(alpha: 0.15)
                              : const Color(0xFFF0F9FF),
                          foregroundColor: dark
                              ? const Color(0xFF38BDF8)
                              : const Color(0xFF0284C7),
                          side: BorderSide(
                            color: const Color(0xFF0284C7).withValues(alpha: 0.35),
                            width: 1.2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                          padding: EdgeInsets.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: () => ctrl.onChallengeTapped(challenge),
                        icon: Icon(
                          Icons.notifications_outlined,
                          size: 16,
                          color: dark
                              ? const Color(0xFF38BDF8)
                              : const Color(0xFF0284C7),
                        ),
                        label: Text(
                          'Scheduled',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: dark
                                ? const Color(0xFF38BDF8)
                                : const Color(0xFF0284C7),
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
