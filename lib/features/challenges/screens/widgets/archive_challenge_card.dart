import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:matricmate/common/widgets/loaders/circular_loading.dart';
import 'package:matricmate/features/challenges/constants/challenge_colors.dart';
import 'package:matricmate/features/challenges/controllers/challenge_archive_controller.dart';
import 'package:matricmate/features/challenges/models/challenge_model.dart';
import 'package:matricmate/features/challenges/screens/challenge_attempt_screen.dart';
import 'package:matricmate/features/challenges/screens/challenge_practice_screen.dart';
import 'package:matricmate/features/challenges/screens/leaderboard_screen.dart';
import 'package:matricmate/features/personalization/controllers/user_controller.dart';
import 'package:matricmate/routes/app_routes.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/helpers/toast_helper.dart';

class ArchiveChallengeCard extends StatelessWidget {
  const ArchiveChallengeCard({
    super.key,
    required this.challenge,
    required this.ctrl,
    required this.dark,
  });

  final LeaderboardChallengeModel challenge;
  final ChallengeArchiveController ctrl;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final isLive = challenge.isLive;
    final isScheduled = challenge.isScheduled;

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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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

              // Right: Status Icons (Completed, Offline Ready, Overflow Menu)
              Obx(() {
                final isDone = ctrl.isAttemptedOrPracticed(challenge.id);
                final isDown = ctrl.isDownloaded(challenge.id);

                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Completed check
                    if (isDone) ...[
                      const Tooltip(
                        message: 'Completed',
                        child: Icon(
                          Icons.check_circle_rounded,
                          size: 19,
                          color: AppColors.teal,
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],

                    // Offline indicator (icon only)
                    if (isDown) ...[
                      const Tooltip(
                        message: 'Offline ready',
                        child: Icon(
                          Icons.cloud_off_rounded,
                          size: 18,
                          color: AppColors.teal,
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],

                    // Overflow Menu
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
                );
              }),
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

          // ── 4. Action Buttons Row ───────────────────────────────────
          Row(
            children: [
              // Standings Button (Low emphasis)
              TextButton.icon(
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  foregroundColor: AppColors.amber,
                  visualDensity: VisualDensity.compact,
                ),
                onPressed: () => Get.to(
                  () => LeaderboardScreen(
                    challengeId: challenge.id,
                    challengeTitle: challenge.title,
                    audience: challenge.audience,
                  ),
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

              // Primary Action Button (Review / Start / Practice / Download)
              Obx(() {
                final isPremium = ctrl.isPremium;
                final isDone = ctrl.isAttemptedOrPracticed(challenge.id);
                final isDown = ctrl.isDownloaded(challenge.id);
                final isBusy = ctrl.isDownloading[challenge.id] == true;
                final isReviewing = ctrl.isOpeningReview[challenge.id] == true;

                // 1. Pro Locked
                if (!isPremium) {
                  final isPending = UserController.instance.user.value.isPending;
                  return SizedBox(
                    width: 150,
                    height: 42,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isPending
                            ? const Color(0xFFD97706)
                            : Colors.amber.shade700,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        if (isPending) {
                          Get.toNamed(Routes.paymentVerification);
                        } else {
                          ctrl.downloadChallenge(challenge);
                        }
                      },
                      icon: Icon(
                        isPending
                            ? Icons.hourglass_top_rounded
                            : Icons.lock_rounded,
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

                // 2. Completed / Attempted -> Review
                if (isDone) {
                  return SizedBox(
                    width: 150,
                    height: 42,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.teal,
                        foregroundColor: const Color(0xFF04342C),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: isReviewing
                          ? null
                          : () => ctrl.openCompletedChallenge(challenge),
                      icon: isReviewing
                          ? const SizedBox.shrink()
                          : const Icon(
                              Icons.description_outlined,
                              size: 15,
                              color: Color(0xFF04342C),
                            ),
                      label: isReviewing
                          ? const AppCircularButtonLoading(
                              color: Color(0xFF04342C),
                            )
                          : const Text(
                              'Review',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF04342C),
                              ),
                            ),
                    ),
                  );
                }

                // 3. Live challenge: show Start / Continue button
                if (isLive) {
                  if (ctrl.isOffline.value) {
                    return SizedBox(
                      width: 150,
                      height: 42,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade600,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => ToastHelper.warning(
                          'Live challenges require an internet connection.',
                        ),
                        icon: const Icon(Icons.wifi_off_rounded, size: 15),
                        label: const Text(
                          'Needs Internet',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    );
                  }
                  final inProgress = ctrl.isInProgress(challenge.id);
                  return SizedBox(
                    width: 150,
                    height: 42,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.teal,
                        foregroundColor: const Color(0xFF04342C),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => Get.to(
                        () => ChallengeAttemptScreen(
                          challengeId: challenge.id,
                          title: challenge.title,
                          audience: challenge.audience,
                          endsAt: challenge.endsAt,
                          durationMinutes: challenge.durationMinutes,
                        ),
                      ),
                      icon: Icon(
                        inProgress
                            ? Icons.play_arrow_rounded
                            : Icons.play_circle_outline_rounded,
                        size: 16,
                        color: const Color(0xFF04342C),
                      ),
                      label: Text(
                        inProgress ? 'Continue' : 'Start',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF04342C),
                        ),
                      ),
                    ),
                  );
                }

                // 4. Scheduled challenge: Upcoming
                if (isScheduled) {
                  return SizedBox(
                    width: 150,
                    height: 42,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ChallengeColors.scheduled,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: null,
                      icon: const Icon(Icons.schedule_rounded, size: 15),
                      label: const Text(
                        'Upcoming',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                }

                // 5. Downloaded -> Practice
                if (isDown) {
                  return SizedBox(
                    width: 150,
                    height: 42,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.teal,
                        foregroundColor: const Color(0xFF04342C),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
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
                        color: Color(0xFF04342C),
                      ),
                      label: const Text(
                        'Practice',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF04342C),
                        ),
                      ),
                    ),
                  );
                }

                // 6. Not downloaded -> Download
                return SizedBox(
                  width: 150,
                  height: 42,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.teal,
                      foregroundColor: const Color(0xFF04342C),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: isBusy
                        ? null
                        : () => ctrl.downloadChallenge(challenge),
                    icon: isBusy
                        ? const SizedBox.shrink()
                        : const Icon(
                            Icons.download_rounded,
                            size: 15,
                            color: Color(0xFF04342C),
                          ),
                    label: isBusy
                        ? const AppCircularButtonLoading(
                            color: Color(0xFF04342C),
                          )
                        : const Text(
                            'Download',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF04342C),
                            ),
                          ),
                  ),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }
}
