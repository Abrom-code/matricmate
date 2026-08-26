import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart';
import 'package:matricmate/common/widgets/loaders/circular_loading.dart';
import 'package:matricmate/features/challenges/constants/challenge_colors.dart';
import 'package:matricmate/features/challenges/controllers/challenge_home_controller.dart';
import 'package:matricmate/features/challenges/models/challenge_model.dart';
import 'package:matricmate/features/challenges/screens/leaderboard_screen.dart';
import 'package:matricmate/features/challenges/screens/widgets/challenge_status_pill.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/constants/sizes.dart';

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

  static final _dateFormat = DateFormat('MMM dd • HH:mm');

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final _ = ctrl.now.value;
      final isPremium = ctrl.isPremium;
      final isLive = challenge.isLive;
      final isScheduled = challenge.isScheduled;

      Color borderColor;
      if (!isPremium) {
        borderColor = dark ? AppColors.darkBorder : AppColors.borderPrimary;
      } else if (isLive) {
        borderColor = AppColors.primary;
      } else if (isScheduled) {
        borderColor = ChallengeColors.scheduled;
      } else {
        borderColor = dark ? AppColors.darkBorder : AppColors.borderPrimary;
      }

      return Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
          side: BorderSide(
            color: borderColor,
            width: isLive && isPremium ? 1.5 : 1.0,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
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
                    if (!isPremium) ...[
                      const SizedBox(width: AppSizes.xs),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: Colors.amber.withValues(alpha: 0.3),
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.lock_rounded,
                              size: 10.5,
                              color: Colors.amber,
                            ),
                            SizedBox(width: 3),
                            Text(
                              'PRO',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                color: Colors.amber,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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
                          const Icon(
                            Iconsax.calendar_1_copy,
                            size: 14,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isLive
                                ? 'Ends: ${challenge.endsAt != null ? _dateFormat.format(challenge.endsAt!) : '--'}'
                                : 'Starts: ${_dateFormat.format(challenge.startsAt!)}',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: dark
                                  ? Colors.white70
                                  : AppColors.textSecondary,
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
                              padding: const EdgeInsets.symmetric(vertical: 8),
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
                            icon: const Icon(Iconsax.ranking_copy, size: 14),
                            label: const Text(
                              'Standings',
                              style: TextStyle(fontSize: 11.5),
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
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                          onPressed: () => ctrl.onChallengeTapped(challenge),
                          icon: const Icon(Icons.lock_rounded, size: 15),
                          label: Text(
                            isLive
                                ? 'Unlock (Pro)'
                                : 'Unlock to Join (Pro)',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
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
                              padding: const EdgeInsets.symmetric(vertical: 8),
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
                            icon: const Icon(Iconsax.ranking_copy, size: 14),
                            label: const Text(
                              'Standings',
                              style: TextStyle(fontSize: 11.5),
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
                                              padding: const EdgeInsets.symmetric(vertical: 8),
                                            ),
                                            onPressed: null,
                                            child: const AppCircularButtonLoading(color: Colors.white),
                                          )
                                        : FilledButton.icon(
                                            style: FilledButton.styleFrom(
                                              backgroundColor: ChallengeColors.completed,
                                              padding: const EdgeInsets.symmetric(vertical: 8),
                                            ),
                                            onPressed: () => ctrl.openCompletedChallenge(challenge),
                                            icon: const Icon(
                                              Iconsax.document_text_1_copy,
                                              size: 16,
                                            ),
                                            label: const Text(
                                              'Review Attempt',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                          );
                                  },
                                )
                              : FilledButton.icon(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 8),
                                  ),
                                  onPressed: () =>
                                      ctrl.onChallengeTapped(challenge),
                                  icon: const Icon(
                                    Iconsax.play_circle_copy,
                                    size: 16,
                                  ),
                                  label: const Text(
                                    'Start Challenge',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
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
      );
    });
  }
}
