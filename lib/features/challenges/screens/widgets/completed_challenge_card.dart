import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:matricmate/common/widgets/loaders/circular_loading.dart';
import 'package:matricmate/features/challenges/constants/challenge_colors.dart';
import 'package:matricmate/features/challenges/controllers/challenge_home_controller.dart';
import 'package:matricmate/features/challenges/models/challenge_model.dart';
import 'package:matricmate/features/challenges/screens/challenge_practice_screen.dart';
import 'package:matricmate/features/challenges/screens/leaderboard_screen.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/constants/sizes.dart';
import 'package:matricmate/utils/helpers/ethiopian_time_helper.dart';

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
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Top Header Row: Subject, Audience, Status Badge, Manage Button ──
            Row(
              children: [
                // Subject Tag
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: dark ? 0.2 : 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: dark ? 0.3 : 0.15),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Iconsax.book_1_copy,
                        size: 11,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        challenge.subjectName ?? 'Subject',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),

                // Audience Tag
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: dark
                        ? Colors.white.withValues(alpha: 0.07)
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    challenge.audience.toUpperCase(),
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                      color: dark ? Colors.white70 : AppColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(width: 6),

                // Dynamic Status Pill (Completed / Downloaded)
                Obx(() {
                  final isDown = ctrl.isDownloaded(challenge.id);
                  final isDone = ctrl.isAttemptedOrPracticed(challenge.id);

                  if (isDone) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: ChallengeColors.completed.withValues(alpha: dark ? 0.2 : 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: ChallengeColors.completed.withValues(alpha: 0.25),
                          width: 0.8,
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            size: 11.5,
                            color: ChallengeColors.completed,
                          ),
                          SizedBox(width: 3.5),
                          Text(
                            'Completed',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: ChallengeColors.completed,
                            ),
                          ),
                        ],
                      ),
                    );
                  } else if (isDown) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0284C7).withValues(alpha: dark ? 0.2 : 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFF0284C7).withValues(alpha: 0.25),
                          width: 0.8,
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.download_done_rounded,
                            size: 11.5,
                            color: Color(0xFF0284C7),
                          ),
                          SizedBox(width: 3.5),
                          Text(
                            'Downloaded',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0284C7),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                }),

                const Spacer(),

                // Manage / Delete Button
                Obx(() {
                  final isDown = ctrl.isDownloaded(challenge.id);
                  final isDone = ctrl.isAttemptedOrPracticed(challenge.id);
                  if (isDown || isDone) {
                    return Tooltip(
                      message: 'Manage challenge data',
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () =>
                            ctrl.showChallengeManageSheet(context, challenge),
                        child: Container(
                          padding: const EdgeInsets.all(5.5),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: dark ? 0.16 : 0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Iconsax.trash_copy,
                            size: 13.5,
                            color: AppColors.error,
                          ),
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                }),
              ],
            ),
            const SizedBox(height: 12),

            // ── Challenge Title ───────────────────────────────────────
            Text(
              challenge.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                height: 1.3,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 10),

            // ── Metadata Chips Row ────────────────────────────────────
            Wrap(
              spacing: 8,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                // Closed Date chip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: dark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(
                      color: dark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Iconsax.calendar_tick_copy,
                        size: 12.5,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        challenge.endsAt != null
                            ? 'Closed ${EthiopianTimeHelper.formatDate(challenge.endsAt!)}'
                            : 'Closed Round',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: dark ? Colors.white70 : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                // Question Count chip
                if (challenge.questionCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: dark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(7),
                      border: Border.all(
                        color: dark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Iconsax.document_copy,
                          size: 12.5,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '${challenge.questionCount} Questions',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: dark ? Colors.white70 : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Duration chip (if > 0)
                if (challenge.durationMinutes > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: dark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(7),
                      border: Border.all(
                        color: dark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Iconsax.timer_1_copy,
                          size: 12.5,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '${challenge.durationMinutes} mins',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: dark ? Colors.white70 : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),

            // ── Action Buttons Row ────────────────────────────────────
            Row(
              children: [
                // Standings Button
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 8),
                      minimumSize: const Size(0, 36),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      backgroundColor: dark
                          ? Colors.amber.withValues(alpha: 0.08)
                          : const Color(0xFFFFFBEB),
                      foregroundColor: dark
                          ? const Color(0xFFFDE68A)
                          : const Color(0xFFB45309),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      side: BorderSide(
                        color: Colors.amber.withValues(alpha: dark ? 0.3 : 0.35),
                        width: 0.9,
                      ),
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
                      size: 14.5,
                      color: Color(0xFFF59E0B),
                    ),
                    label: const Text(
                      'Standings',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Primary Action Button
                Obx(() {
                  final isPremium = ctrl.isPremium;
                  final isDown = ctrl.isDownloaded(challenge.id);
                  final isDone = ctrl.isAttemptedOrPracticed(challenge.id);
                  final isBusy = ctrl.isDownloading[challenge.id] == true;

                  // 1. Pro Locked state
                  if (!isPremium) {
                    return Expanded(
                      flex: 2,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.amber.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 8),
                          minimumSize: const Size(0, 36),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () => ctrl.downloadChallenge(challenge),
                        icon: const Icon(Icons.lock_rounded, size: 13.5),
                        label: const Text(
                          'Unlock (Pro)',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  }

                  // 2. Completed / Attempted -> Review
                  if (isDone) {
                    final isReviewing = ctrl.isOpeningReview[challenge.id] == true;
                    return Expanded(
                      flex: 2,
                      child: isReviewing
                          ? FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: ChallengeColors.completed,
                                padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 8),
                                minimumSize: const Size(0, 36),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: null,
                              child: const AppCircularButtonLoading(color: Colors.white),
                            )
                          : FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor: ChallengeColors.completed,
                                padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 8),
                                minimumSize: const Size(0, 36),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: () => ctrl.openCompletedChallenge(challenge),
                              icon: const Icon(
                                Iconsax.document_text_1_copy,
                                size: 14.5,
                              ),
                              label: const Text(
                                'Review',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                    );
                  }

                  // 3. Downloaded -> Practice
                  if (isDown) {
                    return Expanded(
                      flex: 2,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF0284C7),
                          padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 8),
                          minimumSize: const Size(0, 36),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () => Get.to(
                          () => ChallengePracticeScreen(
                            challengeId: challenge.id,
                            title: challenge.title,
                          ),
                        ),
                        icon: const Icon(Iconsax.book_1_copy, size: 14.5),
                        label: const Text(
                          'Practice',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  }

                  // 4. Not downloaded -> Download
                  return Expanded(
                    flex: 2,
                    child: isBusy
                        ? FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 8),
                              minimumSize: const Size(0, 36),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: null,
                            child: const AppCircularButtonLoading(color: Colors.white),
                          )
                        : FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 8),
                              minimumSize: const Size(0, 36),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: () => ctrl.downloadChallenge(challenge),
                            icon: const Icon(
                              Iconsax.document_download_copy,
                              size: 14.5,
                            ),
                            label: const Text(
                              'Download',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                  );
                }),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
