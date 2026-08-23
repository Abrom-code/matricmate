import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:matricmate/common/widgets/loaders/circular_loading.dart';
import 'package:matricmate/features/challenges/controllers/leaderboard_controller.dart';
import 'package:matricmate/features/challenges/models/challenge_leaderboard_entry.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/constants/sizes.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({
    super.key,
    this.challengeId,
    this.challengeTitle,
    this.audience,
    this.userScore,
    this.userTimeSeconds,
  });

  final String? challengeId;
  final String? challengeTitle;
  final String? audience;
  final int? userScore;
  final int? userTimeSeconds;

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  late final LeaderboardController _ctrl;
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _ctrl = Get.put(
      LeaderboardController(
        challengeId: widget.challengeId,
        audience: widget.audience,
      ),
      tag: 'student_lb_${widget.challengeId ?? 'global'}',
    );
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = AppHelperFunctions.isDark(context);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.challengeTitle ?? 'Leaderboard Standings',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            Obx(() {
              final stream = _ctrl.activeStream.value;
              final label = stream == 'social' ? 'Social Stream' : 'Natural Stream';
              return Text(
                '$label • Top Performers',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: dark ? Colors.white60 : AppColors.textSecondary,
                ),
              );
            }),
          ],
        ),
        actions: [
          Obx(() {
            if (_ctrl.isManualRefreshing.value) {
              return const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Center(
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2.2),
                  ),
                ),
              );
            }
            return IconButton(
              tooltip: 'Refresh Rankings',
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () => _ctrl.manualRefresh(),
            );
          }),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // ── Period Tabs (This Challenge / This Week / This Month) ────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: 8),
            decoration: BoxDecoration(
              color: dark ? AppColors.darkCard : AppColors.white,
              border: Border(
                bottom: BorderSide(
                  color: dark ? AppColors.darkBorder : AppColors.borderPrimary,
                ),
              ),
            ),
            child: Obx(
              () => SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    if (widget.challengeId != null) ...[
                      _PeriodTabChip(
                        label: 'This Challenge',
                        icon: Iconsax.cup_copy,
                        selected: _ctrl.activeTab.value == 'challenge',
                        onTap: () => _ctrl.setTab('challenge'),
                      ),
                      const SizedBox(width: 8),
                    ],
                    _PeriodTabChip(
                      label: 'This Week',
                      icon: Iconsax.calendar_1_copy,
                      selected: _ctrl.activeTab.value == 'weekly',
                      onTap: () => _ctrl.setTab('weekly'),
                    ),
                    const SizedBox(width: 8),
                    _PeriodTabChip(
                      label: 'This Month',
                      icon: Iconsax.calendar_copy,
                      selected: _ctrl.activeTab.value == 'monthly',
                      onTap: () => _ctrl.setTab('monthly'),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Main Leaderboard List ─────────────────────────────────────────
          Expanded(
            child: Obx(() {
              if (_ctrl.isLoading.value) {
                return const AppCircularLoading(title: 'Computing standings...');
              }

              if (_ctrl.entries.isEmpty) {
                return RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: () => _ctrl.loadLeaderboard(),
                  child: LayoutBuilder(
                    builder: (context, constraints) => SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: constraints.maxHeight),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Iconsax.cup_copy, size: 48, color: dark ? Colors.white24 : AppColors.textSecondary),
                              const SizedBox(height: AppSizes.md),
                              const Text(
                                'No attempts recorded yet for this stream',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Be the first to compete and claim rank #1!',
                                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }

              final top3 = _ctrl.entries.take(3).toList();
              final rest = _ctrl.entries.skip(3).toList();

              return RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () => _ctrl.loadLeaderboard(),
                child: ListView(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.all(AppSizes.md),
                  children: [
                    // ── Podium for Top 3 ───────────────────────────────────
                    if (top3.isNotEmpty) ...[
                      _PodiumView(top3: top3, dark: dark),
                      const SizedBox(height: AppSizes.spaceBtwSections),
                    ],

                    // ── Remaining Rankings (#4+) ───────────────────────────
                    if (rest.isNotEmpty) ...[
                      const Text(
                        'All Rankings',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppSizes.sm),
                      ...rest.map(
                        (e) => _StudentLeaderboardTile(
                          entry: e,
                          isCurrentUser: e.userId == _ctrl.currentUserId,
                          dark: dark,
                        ),
                      ),
                    ],
                    const SizedBox(height: 80),
                  ],
                ),
              );
            }),
          ),

          // ── Pinned Current User Rank Bar ─────────────────────────────────
          Obx(() {
            final userEntry = _ctrl.currentUserEntry;
            if (userEntry == null) return const SizedBox.shrink();

            return Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.md,
                vertical: AppSizes.sm,
              ),
              decoration: BoxDecoration(
                color: dark ? AppColors.darkCard : AppColors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
                border: Border(
                  top: BorderSide(
                    color: dark ? AppColors.darkBorder : AppColors.borderPrimary,
                  ),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '#${userEntry.rank}',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSizes.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Your Standing',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            userEntry.fullName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${userEntry.score} pts',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            color: AppColors.primary,
                          ),
                        ),
                        Text(
                          userEntry.formattedTime,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ── Podium View ──────────────────────────────────────────────────────────────

class _PodiumView extends StatelessWidget {
  const _PodiumView({required this.top3, required this.dark});

  final List<ChallengeLeaderboardEntry> top3;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final first = top3.isNotEmpty ? top3[0] : null;
    final second = top3.length > 1 ? top3[1] : null;
    final third = top3.length > 2 ? top3[2] : null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // #2 Silver
          Expanded(
            child: second != null
                ? _PodiumStep(
                    entry: second,
                    rank: 2,
                    height: 110,
                    color: const Color(0xFF94A3B8),
                    dark: dark,
                  )
                : const SizedBox.shrink(),
          ),
          const SizedBox(width: 8),

          // #1 Gold
          Expanded(
            child: first != null
                ? _PodiumStep(
                    entry: first,
                    rank: 1,
                    height: 140,
                    color: const Color(0xFFF59E0B),
                    dark: dark,
                  )
                : const SizedBox.shrink(),
          ),
          const SizedBox(width: 8),

          // #3 Bronze
          Expanded(
            child: third != null
                ? _PodiumStep(
                    entry: third,
                    rank: 3,
                    height: 90,
                    color: const Color(0xFFD97706),
                    dark: dark,
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _PodiumStep extends StatelessWidget {
  const _PodiumStep({
    required this.entry,
    required this.rank,
    required this.height,
    required this.color,
    required this.dark,
  });

  final ChallengeLeaderboardEntry entry;
  final int rank;
  final double height;
  final Color color;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Avatar circle
        Stack(
          alignment: Alignment.topRight,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.15),
                border: Border.all(color: color, width: 2),
              ),
              child: Center(
                child: Text(
                  entry.fullName.isNotEmpty ? entry.fullName[0].toUpperCase() : '?',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
              ),
            ),
            if (rank == 1)
              const Positioned(
                top: -4,
                right: -2,
                child: Icon(Icons.star_rounded, size: 16, color: Color(0xFFF59E0B)),
              ),
          ],
        ),
        const SizedBox(height: 6),

        // Name
        Text(
          entry.fullName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11.5),
        ),
        const SizedBox(height: 2),

        // Score
        Text(
          '${entry.score} pts',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 4),

        // Step Pillar
        Container(
          height: height,
          width: double.infinity,
          decoration: BoxDecoration(
            color: color.withValues(alpha: dark ? 0.18 : 0.12),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8),
              topRight: Radius.circular(8),
            ),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '#$rank',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
              Text(
                entry.formattedTime,
                style: TextStyle(
                  fontSize: 10,
                  color: dark ? Colors.white60 : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Student Leaderboard Tile (#4+) ───────────────────────────────────────────

class _StudentLeaderboardTile extends StatelessWidget {
  const _StudentLeaderboardTile({
    required this.entry,
    required this.isCurrentUser,
    required this.dark,
  });

  final ChallengeLeaderboardEntry entry;
  final bool isCurrentUser;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.sm),
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: 10),
      decoration: BoxDecoration(
        color: isCurrentUser
            ? AppColors.primary.withValues(alpha: dark ? 0.15 : 0.07)
            : (dark ? AppColors.darkCard : AppColors.white),
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusSm),
        border: Border.all(
          color: isCurrentUser
              ? AppColors.primary
              : (dark ? AppColors.darkBorder : AppColors.borderPrimary),
          width: isCurrentUser ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: dark ? AppColors.darkContainer : AppColors.grey.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Text(
              '#${entry.rank}',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
            ),
          ),
          const SizedBox(width: AppSizes.md),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isCurrentUser ? '${entry.fullName} (You)' : entry.fullName,
                  style: TextStyle(
                    fontWeight: isCurrentUser ? FontWeight.w800 : FontWeight.w600,
                    fontSize: 13,
                    color: isCurrentUser ? AppColors.primary : null,
                  ),
                ),
                Text(
                  '${entry.stream.toUpperCase()} Stream • ${entry.challengesTaken} challenges',
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${entry.score} pts',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13.5,
                  color: AppColors.primary,
                ),
              ),
              Text(
                entry.formattedTime,
                style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PeriodTabChip extends StatelessWidget {
  const _PeriodTabChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      showCheckmark: false,
      avatar: Icon(
        icon,
        size: 14,
        color: selected ? Colors.white : AppColors.textSecondary,
      ),
      label: Text(label),
      selected: selected,
      selectedColor: AppColors.primary,
      backgroundColor: Colors.transparent,
      labelStyle: TextStyle(
        color: selected ? Colors.white : AppColors.textSecondary,
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
        fontSize: 12,
      ),
      onSelected: (_) => onTap(),
    );
  }
}
