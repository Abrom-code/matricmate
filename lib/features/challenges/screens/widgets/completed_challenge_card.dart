import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:matricmate/common/widgets/loaders/circular_loading.dart';
import 'package:matricmate/features/challenges/controllers/challenge_home_controller.dart';
import 'package:matricmate/features/challenges/models/challenge_model.dart';
import 'package:matricmate/features/challenges/screens/challenge_attempt_screen.dart';
import 'package:matricmate/features/challenges/screens/challenge_practice_screen.dart';
import 'package:matricmate/features/personalization/controllers/user_controller.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/helpers/challenge_access_helper.dart';

class CompletedChallengeCard extends StatelessWidget {
  const CompletedChallengeCard({
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
      final canAccess = ctrl.canAccess(challenge);
      final isDone = ctrl.isAttemptedOrPracticed(challenge.id, setId: challenge.setId);
      final isPending = UserController.instance.user.value.isPending;

      final closeDateStr = challenge.endsAt != null
          ? 'Closes ${DateFormat('MMM dd').format(challenge.endsAt!)}'
          : 'Closed';

      final durationMins = challenge.durationMinutes > 0
          ? challenge.durationMinutes
          : (challenge.durationSeconds / 60).round();

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
            // ── 1. Header Row ──────────────────────────────────────────
            Row(
              children: [
                // Left: Subject Chip
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.teal.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.menu_book_rounded,
                        size: 13,
                        color: AppColors.teal,
                      ),
                      const SizedBox(width: 5),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 160),
                        child: Text(
                          challenge.subjectName ?? 'Subject',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.teal,
                          ),
                        ),
                      ),
                    ],
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

                // Right: Overflow Menu
                Tooltip(
                  message: 'More options',
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () =>
                        ctrl.showChallengeManageSheet(context, challenge),
                    child: const Padding(
                      padding: EdgeInsets.all(2),
                      child: Icon(
                        Icons.more_vert_rounded,
                        size: 18,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // ── 2. Challenge Title ──────────────────────────────────────
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

            const SizedBox(height: 14),

            // ── 3. Meta Chips Row ───────────────────────────────────────
            Row(
              children: [
                // Closes Date Chip
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: dark
                        ? Colors.white.withValues(alpha: 0.05)
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.event_busy_rounded,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        closeDateStr,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 10),

                // Duration Chip
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: dark
                        ? Colors.white.withValues(alpha: 0.05)
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.timer_outlined,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '$durationMins mins',
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ── 4. Action Buttons ──────────────────────────────────────
            Obx(() {
              final isDown = ctrl.isDownloaded(
                challenge.id,
                setId: challenge.setId,
              );
              final isBusy = ctrl.isDownloading[challenge.id] == true;
              final isReviewing =
                  ctrl.isOpeningReview[challenge.id] == true;

              // 1. Pro Locked
              if (!canAccess) {
                return SizedBox(
                  width: double.infinity,
                  height: 44,
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
                      isPending
                          ? Icons.hourglass_top_rounded
                          : Icons.lock,
                      size: 15,
                    ),
                    label: Text(
                      isPending ? 'Verifying' : 'Unlock (Pro)',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              }

              // 2. Needs Download -> Download
              if (!isDown) {
                return SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: Material(
                    color: isBusy
                        ? AppColors.teal.withValues(alpha: 0.6)
                        : AppColors.teal,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: isBusy
                          ? null
                          : () => ctrl.downloadChallenge(challenge),
                      child: Center(
                        child: isBusy
                            ? const AppCircularButtonLoading(
                                color: Colors.white,
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.download_rounded,
                                    size: 18,
                                    color: Colors.white,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Download',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                );
              }

              // 3. Challenge is Completed -> Review and Redo (Leaderboard button removed!)
              if (isDone) {
                return Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 44,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(
                              color: AppColors.primary,
                              width: 1.2,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: EdgeInsets.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          onPressed: isReviewing
                              ? null
                              : () => ctrl.openCompletedChallenge(challenge),
                          icon: isReviewing
                              ? const SizedBox.shrink()
                              : const Icon(
                                  Icons.description_outlined,
                                  size: 15,
                                ),
                          label: isReviewing
                              ? const AppCircularButtonLoading(
                                  color: AppColors.primary,
                                )
                              : const Text(
                                  'Review',
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SizedBox(
                        height: 44,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.teal,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: EdgeInsets.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          onPressed: () => Get.to(
                            () => ChallengeAttemptScreen(
                              challengeId: challenge.id,
                              title: challenge.title,
                              audience: challenge.audience,
                              durationMinutes: challenge.durationMinutes,
                              setId: challenge.setId,
                              isRedo: true,
                            ),
                          ),
                          icon: const Icon(
                            Icons.replay_rounded,
                            size: 15,
                            color: Colors.white,
                          ),
                          label: const Text(
                            'Redo',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }

              // 4. Downloaded but Not Attempted Yet -> Standings + Practice
              return Row(
                children: [
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      foregroundColor: AppColors.amber,
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: () => ChallengeAccessHelper.openLeaderboard(
                      challengeId: challenge.id,
                      challengeTitle: challenge.title,
                      audience: challenge.audience,
                    ),
                    icon: const Icon(
                      Icons.leaderboard_rounded,
                      size: 15,
                      color: AppColors.amber,
                    ),
                    label: const Text(
                      'Standings',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.amber,
                      ),
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: 150,
                    height: 44,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.teal,
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: AppColors.teal),
                        elevation: 0,
                        padding: EdgeInsets.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => Get.to(
                        () => ChallengePracticeScreen(
                          challengeId: challenge.id,
                          title: challenge.title,
                        ),
                      ),
                      icon: const Icon(
                        Icons.menu_book_rounded,
                        size: 15,
                        color: Colors.white,
                      ),
                      label: const Text(
                        'Practice',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }),
        ],
      ),
    );
  });
}
}
