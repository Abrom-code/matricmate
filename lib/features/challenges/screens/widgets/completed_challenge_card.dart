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
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        color: dark ? AppColors.darkCard : AppColors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: dark
                ? Colors.black.withValues(alpha: 0.25)
                : Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Row: Subject, Audience, Completed Badge, Delete Button in top right
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    challenge.subjectName ?? 'Subject',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: AppSizes.xs),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: dark ? Colors.white10 : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    challenge.audience.toUpperCase(),
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w600,
                      color: dark ? Colors.white70 : AppColors.textSecondary,
                    ),
                  ),
                ),

                Obx(() {
                  final isDown = ctrl.isDownloaded(challenge.id);
                  final isDone = ctrl.isAttemptedOrPracticed(challenge.id);
                  if (isDone) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2.5,
                      ),
                      decoration: BoxDecoration(
                        color: ChallengeColors.completed.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            size: 12,
                            color: ChallengeColors.completed,
                          ),
                          SizedBox(width: 3.5),
                          Text(
                            'Done',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: ChallengeColors.completed,
                            ),
                          ),
                        ],
                      ),
                    );
                  } else if (isDown) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2.5,
                      ),
                      decoration: BoxDecoration(
                        color: ChallengeColors.completed.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.download_done_rounded,
                            size: 12,
                            color: ChallengeColors.completed,
                          ),
                          SizedBox(width: 3.5),
                          Text(
                            'Downloaded',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: ChallengeColors.completed,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                }),
                const Spacer(),
                Obx(() {
                  final isDown = ctrl.isDownloaded(challenge.id);
                  final isDone = ctrl.isAttemptedOrPracticed(challenge.id);
                  if (isDown || isDone) {
                    return IconButton(
                      tooltip: 'Manage challenge data',
                      icon: const Icon(
                        Iconsax.trash_copy,
                        size: 15,
                        color: AppColors.error,
                      ),
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () =>
                          ctrl.showChallengeManageSheet(context, challenge),
                    );
                  }
                  return const SizedBox.shrink();
                }),
              ],
            ),
            const SizedBox(height: 10),

            // Title
            Text(
              challenge.title,
              style: const TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 8),

            // Date & Meta
            Wrap(
              spacing: 12,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Iconsax.calendar_tick_copy,
                      size: 13,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    if (challenge.endsAt != null)
                      Text.rich(
                        TextSpan(
                          text: 'Closed: ',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            color: dark ? Colors.white70 : AppColors.textSecondary,
                          ),
                          children: [
                            TextSpan(
                              text: EthiopianTimeHelper.formatDate(challenge.endsAt!),
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: dark ? Colors.white : Colors.black87,
                              ),
                            ),
                            TextSpan(
                              text: ' • ${EthiopianTimeHelper.formatGregorianTime(challenge.endsAt!)} ',
                            ),
                            TextSpan(
                              text: '(${EthiopianTimeHelper.formatEthiopianTime(challenge.endsAt!)} ET)',
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Text(
                        'Closed Round',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: dark ? Colors.white70 : AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
                if (challenge.questionCount > 0)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Iconsax.document_copy,
                        size: 13,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${challenge.questionCount} Questions',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: dark ? Colors.white60 : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Action Buttons (Rankings + Review / Practice / Download / Unlock)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 4.5, horizontal: 8),
                      minimumSize: const Size(0, 31),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      backgroundColor: dark
                          ? Colors.white.withValues(alpha: 0.04)
                          : const Color(0xFFF8FAFC),
                      foregroundColor:
                          dark ? Colors.white : const Color(0xFF0F172A),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      side: BorderSide(
                        color: dark
                            ? AppColors.darkBorder
                            : AppColors.borderPrimary,
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
                      size: 14,
                      color: Color(0xFFF59E0B),
                    ),
                    label: const Text(
                      'Standings',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Obx(() {
                  final isPremium = ctrl.isPremium;
                  final isDown = ctrl.isDownloaded(challenge.id);
                  final isDone = ctrl.isAttemptedOrPracticed(challenge.id);
                  final isBusy = ctrl.isDownloading[challenge.id] == true;

                  if (!isPremium) {
                    return Expanded(
                      flex: 2,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.amber.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 4.5, horizontal: 8),
                          minimumSize: const Size(0, 31),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () => ctrl.downloadChallenge(challenge),
                        icon: const Icon(Icons.lock_rounded, size: 13),
                        label: const Text(
                          'Unlock (Pro)',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  }

                  // 1. If completed/attempted -> show Review button with loading state
                  if (isDone) {
                    final isReviewing = ctrl.isOpeningReview[challenge.id] == true;
                    return Expanded(
                      flex: 2,
                      child: isReviewing
                          ? FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: ChallengeColors.completed,
                                padding: const EdgeInsets.symmetric(vertical: 4.5, horizontal: 8),
                                minimumSize: const Size(0, 31),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: null,
                              child: const AppCircularButtonLoading(color: Colors.white),
                            )
                          : FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor: ChallengeColors.completed,
                                padding: const EdgeInsets.symmetric(vertical: 4.5, horizontal: 8),
                                minimumSize: const Size(0, 31),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: () => ctrl.openCompletedChallenge(challenge),
                              icon: const Icon(
                                Iconsax.document_text_1_copy,
                                size: 14,
                              ),
                              label: const Text(
                                'Review',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                    );
                  }

                  // 2. If downloaded -> show Practice button
                  if (isDown) {
                    return Expanded(
                      flex: 2,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: ChallengeColors.completed,
                          padding: const EdgeInsets.symmetric(vertical: 4.5, horizontal: 8),
                          minimumSize: const Size(0, 31),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () => Get.to(
                          () => ChallengePracticeScreen(
                            challengeId: challenge.id,
                            title: challenge.title,
                          ),
                        ),
                        icon: const Icon(Iconsax.book_1_copy, size: 14),
                        label: const Text(
                          'Practice',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  }

                  // 3. Not downloaded -> show Download button
                  return Expanded(
                    flex: 2,
                    child: isBusy
                        ? FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(vertical: 4.5, horizontal: 8),
                              minimumSize: const Size(0, 31),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: null,
                            child: const AppCircularButtonLoading(color: Colors.white),
                          )
                        : FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(vertical: 4.5, horizontal: 8),
                              minimumSize: const Size(0, 31),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: () => ctrl.downloadChallenge(challenge),
                            icon: const Icon(
                              Iconsax.document_download_copy,
                              size: 14,
                            ),
                            label: const Text(
                              'Download',
                              style: TextStyle(
                                fontSize: 11.5,
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
    );
  }
}
