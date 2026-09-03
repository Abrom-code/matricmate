import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:matricmate/common/widgets/loaders/circular_loading.dart';
import 'package:matricmate/features/challenges/constants/challenge_colors.dart';
import 'package:matricmate/features/challenges/controllers/challenge_home_controller.dart';
import 'package:matricmate/features/challenges/models/challenge_model.dart';
import 'package:matricmate/features/challenges/screens/leaderboard_screen.dart';
import 'package:matricmate/features/challenges/screens/widgets/challenge_status_pill.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/constants/sizes.dart';
import 'package:matricmate/utils/helpers/ethiopian_time_helper.dart';

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
      final _ = ctrl.now.value;
      final isPremium = ctrl.isPremium;
      final isLive = challenge.isLive;
      final isScheduled = challenge.isScheduled;

      return Container(
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
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => ctrl.onChallengeTapped(challenge),
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.md),
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Row (Subject, Audience, Lock Badge, Status Badge)
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
                      final isDone = ctrl.isAttemptedOrPracticed(challenge.id);
                      if (!isDone) return const SizedBox.shrink();
                      return Container(
                        margin: const EdgeInsets.only(left: AppSizes.xs),
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
                              'Completed',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: ChallengeColors.completed,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    const Spacer(),
                    Obx(() {
                      final isDown = ctrl.isDownloaded(challenge.id);
                      final isDone = ctrl.isAttemptedOrPracticed(challenge.id);
                      if (isDown || isDone) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: IconButton(
                            tooltip: isDone ? 'Delete challenge practice data' : 'Remove offline download',
                            icon: const Icon(
                              Iconsax.trash_copy,
                              size: 15,
                              color: AppColors.error,
                            ),
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () =>
                                ctrl.confirmDeleteDownload(context, challenge),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    }),
                    ChallengeStatusPill(challenge: challenge, dark: dark),
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
                const SizedBox(height: 10),

                // Meta Details Row (Duration, Starts/Ends, Question Count)
                Wrap(
                  spacing: 12,
                  runSpacing: 6,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Iconsax.timer_1_copy,
                          size: 14,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${challenge.durationMinutes} mins',
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    if (challenge.startsAt != null)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isLive ? Iconsax.calendar_tick_copy : Iconsax.calendar_1_copy,
                            size: 13,
                            color: isLive ? AppColors.success : AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text.rich(
                            TextSpan(
                              text: isLive ? 'Ends: ' : 'Starts: ',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                                color: dark ? Colors.white70 : AppColors.textSecondary,
                              ),
                              children: [
                                TextSpan(
                                  text: EthiopianTimeHelper.formatDate(isLive ? (challenge.endsAt ?? challenge.startsAt!) : challenge.startsAt!),
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: dark ? Colors.white : Colors.black87,
                                  ),
                                ),
                                TextSpan(
                                  text: ' • ${EthiopianTimeHelper.formatGregorianTime(isLive ? (challenge.endsAt ?? challenge.startsAt!) : challenge.startsAt!)} ',
                                ),
                                TextSpan(
                                  text: '(${EthiopianTimeHelper.formatEthiopianTime(isLive ? (challenge.endsAt ?? challenge.startsAt!) : challenge.startsAt!)} ET)',
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
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
                            size: 14,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${challenge.questionCount} Qs',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: dark
                                  ? Colors.white70
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                // Action Banner
                if (!isPremium)
                  Row(
                    children: [
                      if (isLive) ...[
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
                      ],
                      Expanded(
                        flex: isLive ? 2 : 1,
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: isLive
                                ? AppColors.primary
                                : ChallengeColors.scheduled,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 4.5, horizontal: 8),
                            minimumSize: const Size(0, 31),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () => ctrl.onChallengeTapped(challenge),
                          icon: const Icon(Icons.lock_rounded, size: 13),
                          label: Text(
                            isLive
                                ? 'Unlock (Pro)'
                                : 'Unlock to Join (Pro)',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 11.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                else if (isLive)
                  Obx(() {
                    final isDone = ctrl.isAttemptedOrPracticed(challenge.id);
                    return Row(
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
                        Expanded(
                          flex: 2,
                          child: isDone
                              ? Builder(
                                  builder: (_) {
                                    final isReviewing = ctrl.isOpeningReview[challenge.id] == true;
                                    return isReviewing
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
                                                fontWeight: FontWeight.bold,
                                                fontSize: 11.5,
                                              ),
                                            ),
                                          );
                                  },
                                )
                              : Obx(() {
                                  final inProgress = ctrl.isInProgress(challenge.id);
                                  return FilledButton.icon(
                                    style: FilledButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      padding: const EdgeInsets.symmetric(vertical: 4.5, horizontal: 8),
                                      minimumSize: const Size(0, 31),
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    onPressed: () =>
                                        ctrl.onChallengeTapped(challenge),
                                    icon: Icon(
                                      inProgress ? Iconsax.play_copy : Iconsax.play_circle_copy,
                                      size: 14,
                                    ),
                                    label: Text(
                                      inProgress ? 'Continue' : 'Start Challenge',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11.5,
                                      ),
                                    ),
                                  );
                                }),
                        ),
                      ],
                    );
                  })
                else if (isScheduled && challenge.startsAt != null)
                  Obx(
                    () => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: ChallengeColors.scheduled.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Iconsax.clock_copy,
                            size: 14,
                            color: ChallengeColors.scheduled,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Opens in: ${ctrl.formatCountdown(challenge.startsAt!)}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: ChallengeColors.scheduled,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        ),
      );
    });
  }
}
