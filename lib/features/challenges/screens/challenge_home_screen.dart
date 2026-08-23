import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart';
import 'package:matricmate/common/widgets/appbar/modern_appbar.dart';
import 'package:matricmate/common/widgets/exam/premium_bottom_sheet.dart';
import 'package:matricmate/common/widgets/loaders/circular_loading.dart';
import 'package:matricmate/features/challenges/controllers/challenge_home_controller.dart';
import 'package:matricmate/features/challenges/models/challenge_model.dart';
import 'package:matricmate/features/challenges/screens/challenge_archive_screen.dart';
import 'package:matricmate/features/challenges/screens/leaderboard_screen.dart';
import 'package:matricmate/features/personalization/controllers/user_controller.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/constants/sizes.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

class ChallengeHomeScreen extends StatefulWidget {
  const ChallengeHomeScreen({super.key});

  @override
  State<ChallengeHomeScreen> createState() => _ChallengeHomeScreenState();
}

class _ChallengeHomeScreenState extends State<ChallengeHomeScreen> {
  late final ChallengeHomeController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = Get.put(ChallengeHomeController());
  }

  @override
  Widget build(BuildContext context) {
    final dark = AppHelperFunctions.isDark(context);

    return Scaffold(
      appBar: ModernAppbarWithBuilder(
        title: '🏆 Stream Challenges',
        subtitleBuilder: (_) => Obx(() {
          final stream = UserController.instance.user.value.stream;
          if (stream.isEmpty) return const SizedBox.shrink();
          return Text(
            '${stream[0].toUpperCase()}${stream.substring(1)} Stream Competitions',
            style: const TextStyle(
              color: Color(0xFFD1FAE5),
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
            ),
          );
        }),
        actions: [
          IconButton(
            tooltip: 'Past Challenges Archive',
            icon: const Icon(Iconsax.archive_book_copy, color: Colors.white),
            onPressed: () => Get.to(() => const ChallengeArchiveScreen()),
          ),
          IconButton(
            tooltip: 'Period Standings',
            icon: const Icon(Iconsax.ranking_copy, color: Colors.white),
            onPressed: () => Get.to(() => const LeaderboardScreen()),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Obx(() {
        if (_ctrl.isLoading.value && _ctrl.challenges.isEmpty) {
          return const AppCircularLoading(title: 'Loading challenges...');
        }

        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () => _ctrl.loadChallenges(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
              AppSizes.md,
              AppSizes.md,
              AppSizes.md,
              MediaQuery.paddingOf(context).bottom + 100,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Section Title ───────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Available Rounds',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    TextButton.icon(
                      onPressed: () => Get.to(() => const ChallengeArchiveScreen()),
                      icon: const Icon(Iconsax.archive_copy, size: 14),
                      label: const Text('Past Rounds', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
                const SizedBox(height: AppSizes.sm),

                // ── Challenges List ─────────────────────────────────
                if (_ctrl.challenges.isEmpty)
                  _EmptyState(dark: dark)
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _ctrl.challenges.length,
                    separatorBuilder: (_, __) => const SizedBox(height: AppSizes.spaceBtwItems),
                    itemBuilder: (context, index) {
                      final challenge = _ctrl.challenges[index];
                      return _ChallengeTile(
                        challenge: challenge,
                        ctrl: _ctrl,
                        dark: dark,
                      );
                    },
                  ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

// ── Challenge Tile ───────────────────────────────────────────────────────────

class _ChallengeTile extends StatelessWidget {
  const _ChallengeTile({
    required this.challenge,
    required this.ctrl,
    required this.dark,
  });

  final LeaderboardChallengeModel challenge;
  final ChallengeHomeController ctrl;
  final bool dark;

  static final _dateFormat = DateFormat('MMM dd, HH:mm');

  @override
  Widget build(BuildContext context) {
    final isPremium = ctrl.isPremium;
    final isLive = challenge.isLive;
    final isScheduled = challenge.isScheduled;

    Color borderColor;
    if (!isPremium) {
      borderColor = dark ? AppColors.darkBorder : AppColors.borderPrimary;
    } else if (isLive) {
      borderColor = AppColors.primary;
    } else if (isScheduled) {
      borderColor = const Color(0xFF2563EB);
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
              // ── Header Row (Subject, Audience, Status Badge) ──────
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: (challenge.audience == 'both'
                              ? AppColors.secondary
                              : AppColors.primary)
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${challenge.audience.toUpperCase()} STREAM',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: challenge.audience == 'both'
                            ? AppColors.secondary
                            : AppColors.primary,
                      ),
                    ),
                  ),
                  const Spacer(),

                  // State Badge
                  if (!isPremium)
                    const _StateBadge(
                      label: 'PREMIUM ONLY',
                      icon: Iconsax.lock_copy,
                      color: AppColors.amberAccent,
                    )
                  else if (isLive)
                    const _StateBadge(
                      label: 'LIVE NOW 🔥',
                      icon: Iconsax.play_circle_copy,
                      color: AppColors.success,
                    )
                  else if (isScheduled)
                    const _StateBadge(
                      label: 'UPCOMING',
                      icon: Iconsax.clock_copy,
                      color: Color(0xFF2563EB),
                    )
                  else
                    const _StateBadge(
                      label: 'CLOSED',
                      icon: Iconsax.tick_circle_copy,
                      color: Color(0xFF7C3AED),
                    ),
                ],
              ),
              const SizedBox(height: AppSizes.sm + 2),

              // ── Title & Meta ──────────────────────────────────────
              Text(
                challenge.title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Iconsax.timer_1_copy,
                    size: 14,
                    color: dark ? Colors.white60 : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${challenge.durationSeconds ~/ 60} mins time limit',
                    style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                  ),
                  if (challenge.startsAt != null) ...[
                    const Text(' • ', style: TextStyle(color: AppColors.textSecondary)),
                    Text(
                      _dateFormat.format(challenge.startsAt!),
                      style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                    ),
                  ],
                ],
              ),

              const SizedBox(height: AppSizes.md),
              const Divider(height: 1),
              const SizedBox(height: AppSizes.sm),

              // ── Action Footer ─────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Countdown / Info Label
                  if (!isPremium)
                    const Text(
                      'Tap to unlock premium access',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.amberAccent,
                      ),
                    )
                  else if (isScheduled && challenge.startsAt != null)
                    Obx(
                      () => Row(
                        children: [
                          const Icon(Iconsax.clock_copy, size: 14, color: Color(0xFF2563EB)),
                          const SizedBox(width: 4),
                          Text(
                            'Opens in ${ctrl.formatCountdown(challenge.startsAt!)}',
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF2563EB),
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (isLive)
                    const Text(
                      'Timed online round in progress',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.success,
                      ),
                    )
                  else
                    const Text(
                      'Results computed & finalized',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textSecondary,
                      ),
                    ),

                  // Button
                  if (!isPremium)
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.amberAccent,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      onPressed: () => Get.bottomSheet(
                        const PremiumBottomSheet(),
                        isScrollControlled: true,
                      ),
                      icon: const Icon(Iconsax.lock_copy, size: 14),
                      label: const Text('Unlock', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    )
                  else if (isLive)
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      ),
                      onPressed: () => ctrl.onChallengeTapped(challenge),
                      icon: const Icon(Iconsax.play_copy, size: 14),
                      label: const Text('Enter Challenge', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    )
                  else if (isScheduled)
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      onPressed: () => ctrl.onChallengeTapped(challenge),
                      icon: const Icon(Iconsax.clock_copy, size: 14),
                      label: const Text('Locked', style: TextStyle(fontSize: 12)),
                    )
                  else
                    FilledButton.tonalIcon(
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      onPressed: () => ctrl.onChallengeTapped(challenge),
                      icon: const Icon(Iconsax.ranking_copy, size: 14),
                      label: const Text('View Results', style: TextStyle(fontSize: 12)),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StateBadge extends StatelessWidget {
  const _StateBadge({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.dark});

  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSizes.lg),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Iconsax.cup_copy, size: 40, color: AppColors.primary),
            ),
            const SizedBox(height: AppSizes.md),
            const Text(
              'No Challenges Live Right Now',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            const Text(
              'New rounds appear 12 hours before they start.\nCheck back soon or explore past challenges in the archive!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSizes.md),
            OutlinedButton.icon(
              onPressed: () => Get.to(() => const ChallengeArchiveScreen()),
              icon: const Icon(Iconsax.archive_book_copy, size: 16),
              label: const Text('Open Past Challenges Archive'),
            ),
          ],
        ),
      ),
    );
  }
}
