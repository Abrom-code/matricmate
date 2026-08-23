import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart';
import 'package:matricmate/common/widgets/appbar/modern_appbar.dart';
import 'package:matricmate/common/widgets/loaders/circular_loading.dart';
import 'package:matricmate/features/challenges/controllers/challenge_home_controller.dart';
import 'package:matricmate/features/challenges/models/challenge_model.dart';
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

class _ChallengeHomeScreenState extends State<ChallengeHomeScreen>
    with SingleTickerProviderStateMixin {
  late final ChallengeHomeController _ctrl;
  late final TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _ctrl = Get.put(ChallengeHomeController());
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
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
            tooltip: 'Period Standings',
            icon: const Icon(Iconsax.ranking_copy, color: Colors.white),
            onPressed: () => Get.to(() => const LeaderboardScreen()),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // ── TabBar ────────────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: dark ? AppColors.darkCard : AppColors.white,
              border: Border(
                bottom: BorderSide(
                  color: dark ? AppColors.darkBorder : AppColors.borderPrimary,
                ),
              ),
            ),
            child: Obx(
              () => TabBar(
                controller: _tabCtrl,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                labelColor: AppColors.primary,
                unselectedLabelColor: dark ? Colors.white60 : AppColors.textSecondary,
                indicatorColor: AppColors.primary,
                indicatorWeight: 3,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Iconsax.timer_1_copy, size: 16),
                        const SizedBox(width: 6),
                        const Text('Available'),
                        if (_ctrl.availableChallenges.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${_ctrl.availableChallenges.length}',
                              style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppColors.primary),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Iconsax.tick_circle_copy, size: 16),
                        const SizedBox(width: 6),
                        const Text('Completed / Past'),
                        if (_ctrl.completedChallenges.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: dark ? Colors.white12 : const Color(0xFFE2E8F0),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${_ctrl.completedChallenges.length}',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                color: dark ? Colors.white70 : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Tab Views ─────────────────────────────────────────────
          Expanded(
            child: Obx(() {
              if (_ctrl.isLoading.value &&
                  _ctrl.availableChallenges.isEmpty &&
                  _ctrl.completedChallenges.isEmpty) {
                return const AppCircularLoading(title: 'Loading challenges...');
              }

              return TabBarView(
                controller: _tabCtrl,
                children: [
                  // Tab 1: Available Challenges
                  RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: () => _ctrl.loadAllChallenges(),
                    child: _ctrl.availableChallenges.isEmpty
                        ? _EmptyState(
                            title: 'No available rounds currently',
                            subtitle: 'Upcoming challenges will appear here before they open.',
                            dark: dark,
                          )
                        : ListView.separated(
                            padding: EdgeInsets.fromLTRB(
                              AppSizes.md,
                              AppSizes.md,
                              AppSizes.md,
                              MediaQuery.paddingOf(context).bottom + 90,
                            ),
                            itemCount: _ctrl.availableChallenges.length,
                            separatorBuilder: (_, __) => const SizedBox(height: AppSizes.spaceBtwItems),
                            itemBuilder: (context, index) {
                              final challenge = _ctrl.availableChallenges[index];
                              return _AvailableChallengeCard(
                                challenge: challenge,
                                ctrl: _ctrl,
                                dark: dark,
                              );
                            },
                          ),
                  ),

                  // Tab 2: Completed / Past Challenges
                  RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: () => _ctrl.loadAllChallenges(),
                    child: _ctrl.completedChallenges.isEmpty
                        ? _EmptyState(
                            title: 'No completed challenges yet',
                            subtitle: 'Once live challenges end, you can review and practice them here.',
                            dark: dark,
                          )
                        : ListView.separated(
                            padding: EdgeInsets.fromLTRB(
                              AppSizes.md,
                              AppSizes.md,
                              AppSizes.md,
                              MediaQuery.paddingOf(context).bottom + 90,
                            ),
                            itemCount: _ctrl.completedChallenges.length,
                            separatorBuilder: (_, __) => const SizedBox(height: AppSizes.spaceBtwItems),
                            itemBuilder: (context, index) {
                              final challenge = _ctrl.completedChallenges[index];
                              return _CompletedChallengeCard(
                                challenge: challenge,
                                ctrl: _ctrl,
                                dark: dark,
                              );
                            },
                          ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}

// ── Available Challenge Card ─────────────────────────────────────────────────

class _AvailableChallengeCard extends StatelessWidget {
  const _AvailableChallengeCard({
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
              // Header Row (Subject, Audience, Status Badge)
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
                  const Spacer(),
                  _StatusBadge(challenge: challenge, dark: dark),
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
                      const Icon(Iconsax.timer_1_copy, size: 14, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        '${challenge.durationMinutes} mins',
                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  if (challenge.startsAt != null)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Iconsax.calendar_1_copy, size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          isLive
                              ? 'Ends: ${challenge.endsAt != null ? _dateFormat.format(challenge.endsAt!) : '--'}'
                              : 'Starts: ${_dateFormat.format(challenge.startsAt!)}',
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
                        const Icon(Iconsax.document_copy, size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          '${challenge.questionCount} Qs',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: dark ? Colors.white70 : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // Action Banner
              if (isLive)
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  onPressed: () => ctrl.onChallengeTapped(challenge),
                  icon: const Icon(Iconsax.play_circle_copy, size: 16),
                  label: const Text('Start Challenge Now', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                )
              else if (isScheduled && challenge.startsAt != null)
                Obx(
                  () => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Iconsax.clock_copy, size: 14, color: Color(0xFF2563EB)),
                        const SizedBox(width: 6),
                        Text(
                          'Opens in: ${ctrl.formatCountdown(challenge.startsAt!)}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2563EB),
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
  }
}

// ── Completed / Past Challenge Card ──────────────────────────────────────────

class _CompletedChallengeCard extends StatelessWidget {
  const _CompletedChallengeCard({
    required this.challenge,
    required this.ctrl,
    required this.dark,
  });

  final LeaderboardChallengeModel challenge;
  final ChallengeHomeController ctrl;
  final bool dark;

  static final _dateFormat = DateFormat('MMM dd, yyyy');

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
        side: BorderSide(
          color: dark ? AppColors.darkBorder : AppColors.borderPrimary,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Row: Subject, Audience, Offline Indicator
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
                const Spacer(),
                Obx(() {
                  final isDown = ctrl.isDownloaded(challenge.id);
                  if (isDown) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: Colors.teal.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.offline_pin_rounded, size: 12, color: Colors.teal),
                          SizedBox(width: 4),
                          Text('Offline', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.teal)),
                        ],
                      ),
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
            Row(
              children: [
                const Icon(Iconsax.calendar_tick_copy, size: 13, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  challenge.endsAt != null
                      ? 'Closed on ${_dateFormat.format(challenge.endsAt!)}'
                      : 'Closed Round',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: dark ? Colors.white70 : AppColors.textSecondary,
                  ),
                ),
                const Spacer(),
                if (challenge.questionCount > 0)
                  Text(
                    '${challenge.questionCount} Questions',
                    style: TextStyle(fontSize: 11.5, color: dark ? Colors.white60 : AppColors.textSecondary),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Action Buttons (Rankings + Download or Delete & Practice)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      side: BorderSide(
                        color: dark ? AppColors.darkBorder : AppColors.borderPrimary,
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
                    label: const Text('Rankings', style: TextStyle(fontSize: 11.5)),
                  ),
                ),
                const SizedBox(width: 8),
                Obx(() {
                  final isDown = ctrl.isDownloaded(challenge.id);
                  final isBusy = ctrl.isDownloading[challenge.id] == true;

                  if (isDown) {
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Delete Offline Download',
                          icon: const Icon(Iconsax.trash_copy, size: 17, color: AppColors.error),
                          visualDensity: VisualDensity.compact,
                          onPressed: () => ctrl.confirmDeleteDownload(context, challenge),
                        ),
                        const SizedBox(width: 4),
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          ),
                          onPressed: () => ctrl.openCompletedChallenge(challenge),
                          icon: const Icon(Iconsax.book_1_copy, size: 14),
                          label: const Text('Practice', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    );
                  }

                  return Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      onPressed: isBusy ? null : () => ctrl.downloadChallenge(challenge),
                      icon: isBusy
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Iconsax.document_download_copy, size: 14),
                      label: Text(
                        isBusy ? 'Downloading...' : 'Download',
                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
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

// ── Status Badge ─────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.challenge, required this.dark});

  final LeaderboardChallengeModel challenge;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    if (challenge.isLive) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.circle, size: 7, color: Color(0xFFEF4444)),
            SizedBox(width: 4),
            Text(
              'LIVE',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: Color(0xFFEF4444),
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
          color: const Color(0xFF2563EB).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Text(
          'UPCOMING',
          style: TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w700,
            color: Color(0xFF2563EB),
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

// ── Empty State ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.title,
    required this.subtitle,
    required this.dark,
  });

  final String title;
  final String subtitle;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Iconsax.cup_copy,
              size: 48,
              color: dark ? Colors.white24 : AppColors.textSecondary,
            ),
            const SizedBox(height: AppSizes.md),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: dark ? Colors.white60 : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
