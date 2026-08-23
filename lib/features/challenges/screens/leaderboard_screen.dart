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
        title: Text(
          widget.challengeTitle ?? '🏆 Leaderboard Standings',
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh Rankings',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => _ctrl.loadLeaderboard(),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // ── Period & Stream Selector ──────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: 8),
            decoration: BoxDecoration(
              color: dark ? AppColors.darkCard : AppColors.white,
              border: Border(
                bottom: BorderSide(
                  color: dark ? AppColors.darkBorder : AppColors.borderPrimary,
                ),
              ),
            ),
            child: Column(
              children: [
                // Period Tabs
                Obx(
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
                const SizedBox(height: 8),

                // Stream Tabs (Natural / Social)
                Obx(
                  () => Row(
                    children: [
                      const Text(
                        'Stream: ',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 6),
                      ChoiceChip(
                        label: const Text('Natural Stream', style: TextStyle(fontSize: 11)),
                        selected: _ctrl.activeStream.value == 'natural',
                        onSelected: (_) => _ctrl.setStream('natural'),
                        selectedColor: AppColors.primary.withValues(alpha: 0.18),
                        labelStyle: TextStyle(
                          color: _ctrl.activeStream.value == 'natural'
                              ? AppColors.primary
                              : AppColors.textSecondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Social Stream', style: TextStyle(fontSize: 11)),
                        selected: _ctrl.activeStream.value == 'social',
                        onSelected: (_) => _ctrl.setStream('social'),
                        selectedColor: AppColors.secondary.withValues(alpha: 0.18),
                        labelStyle: TextStyle(
                          color: _ctrl.activeStream.value == 'social'
                              ? AppColors.secondary
                              : AppColors.textSecondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Main Leaderboard List ─────────────────────────────────
          Expanded(
            child: Obx(() {
              if (_ctrl.isLoading.value && _ctrl.entries.isEmpty) {
                return const AppCircularLoading(title: 'Computing standings...');
              }

              if (_ctrl.entries.isEmpty) {
                return Center(
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
                    // ── Podium for Top 3 ───────────────────────────
                    if (top3.isNotEmpty) ...[
                      _PodiumView(top3: top3, dark: dark),
                      const SizedBox(height: AppSizes.spaceBtwSections),
                    ],

                    // ── Remaining Rankings (#4+) ───────────────────
                    if (rest.isNotEmpty) ...[
                      const Text(
                        'All Rankings',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: AppSizes.sm),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: rest.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 6),
                        itemBuilder: (context, idx) {
                          final entry = rest[idx];
                          final isMe = entry.userId == _ctrl.currentUserId;
                          return _StudentLeaderboardTile(
                            entry: entry,
                            isCurrentUser: isMe,
                            dark: dark,
                          );
                        },
                      ),
                    ],
                  ],
                ),
              );
            }),
          ),

          // ── Pinned Current User Rank Bar ──────────────────────────
          Obx(() {
            final userEntry = _ctrl.currentUserEntry;
            if (userEntry == null) return const SizedBox.shrink();

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.primary,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Rank #${userEntry.rank}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSizes.md),
                    const Expanded(
                      child: Text(
                        'Your Current Standing',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${userEntry.score} pts',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          userEntry.formattedTime,
                          style: const TextStyle(color: Colors.white70, fontSize: 11),
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
    final ChallengeLeaderboardEntry? first = top3.isNotEmpty ? top3[0] : null;
    final ChallengeLeaderboardEntry? second = top3.length > 1 ? top3[1] : null;
    final ChallengeLeaderboardEntry? third = top3.length > 2 ? top3[2] : null;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // 2nd Place (Left)
        if (second != null)
          Expanded(
            child: _PodiumStep(
              entry: second,
              rank: 2,
              color: const Color(0xFFC0C0C0), // Silver
              height: 125,
              dark: dark,
            ),
          )
        else
          const Spacer(),

        const SizedBox(width: 8),

        // 1st Place (Center)
        if (first != null)
          Expanded(
            child: _PodiumStep(
              entry: first,
              rank: 1,
              color: const Color(0xFFFFD700), // Gold
              height: 155,
              isFirst: true,
              dark: dark,
            ),
          )
        else
          const Spacer(),

        const SizedBox(width: 8),

        // 3rd Place (Right)
        if (third != null)
          Expanded(
            child: _PodiumStep(
              entry: third,
              rank: 3,
              color: const Color(0xFFCD7F32), // Bronze
              height: 110,
              dark: dark,
            ),
          )
        else
          const Spacer(),
      ],
    );
  }
}

class _PodiumStep extends StatelessWidget {
  const _PodiumStep({
    required this.entry,
    required this.rank,
    required this.color,
    required this.height,
    this.isFirst = false,
    required this.dark,
  });

  final ChallengeLeaderboardEntry entry;
  final int rank;
  final Color color;
  final double height;
  final bool isFirst;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Avatar + Rank Crown
        Stack(
          alignment: Alignment.topCenter,
          clipBehavior: Clip.none,
          children: [
            CircleAvatar(
              radius: isFirst ? 26 : 22,
              backgroundColor: color.withValues(alpha: 0.25),
              child: CircleAvatar(
                radius: isFirst ? 23 : 19,
                backgroundColor: color.withValues(alpha: 0.8),
                child: Text(
                  entry.firstName.isNotEmpty ? entry.firstName[0].toUpperCase() : 'S',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            if (isFirst)
              const Positioned(
                top: -12,
                child: Icon(Iconsax.crown_copy, color: Color(0xFFFFD700), size: 20),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          entry.fullName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: isFirst ? 12.5 : 11.5,
          ),
        ),
        Text(
          '${entry.score} pts',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: isFirst ? 13 : 11.5,
            color: color,
          ),
        ),
        const SizedBox(height: 4),

        // Step Pillar
        Container(
          height: height,
          width: double.infinity,
          decoration: BoxDecoration(
            color: color.withValues(alpha: dark ? 0.2 : 0.15),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
          ),
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '#$rank',
                style: TextStyle(
                  fontSize: isFirst ? 26 : 20,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
              Text(
                entry.formattedTime,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: dark ? Colors.white70 : AppColors.darkGrey,
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
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: 10),
      decoration: BoxDecoration(
        color: isCurrentUser
            ? AppColors.primary.withValues(alpha: 0.12)
            : (dark ? AppColors.darkCard : AppColors.white),
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
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
