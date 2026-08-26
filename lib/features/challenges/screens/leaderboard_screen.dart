import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:matricmate/common/widgets/loaders/circular_loading.dart';
import 'package:matricmate/features/challenges/controllers/leaderboard_controller.dart';
import 'package:matricmate/features/challenges/screens/widgets/leaderboard_entry_tile.dart';
import 'package:matricmate/features/challenges/screens/widgets/leaderboard_podium.dart';
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
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            Obx(() {
              final stream = _ctrl.activeStream.value;
              final label =
                  stream == 'social' ? 'Social Stream' : 'Natural Stream';
              return Text(
                '$label • Top Performers',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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
                  child: AppCircularButtonLoading(color: AppColors.primary),
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
            padding:
                const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: 8),
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
                      LeaderboardPeriodChip(
                        label: 'This Challenge',
                        icon: Iconsax.cup_copy,
                        selected: _ctrl.activeTab.value == 'challenge',
                        onTap: () => _ctrl.setTab('challenge'),
                      ),
                      const SizedBox(width: 8),
                    ],
                    LeaderboardPeriodChip(
                      label: 'This Week',
                      icon: Iconsax.calendar_1_copy,
                      selected: _ctrl.activeTab.value == 'weekly',
                      onTap: () => _ctrl.setTab('weekly'),
                    ),
                    const SizedBox(width: 8),
                    LeaderboardPeriodChip(
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
                        constraints:
                            BoxConstraints(minHeight: constraints.maxHeight),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Iconsax.cup_copy,
                                size: 48,
                                color: dark
                                    ? Colors.white24
                                    : AppColors.textSecondary,
                              ),
                              const SizedBox(height: AppSizes.md),
                              const Text(
                                'No attempts recorded yet for this stream',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Be the first to compete and claim rank #1!',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }

              final displayed = _ctrl.displayedEntries;
              final top3 = displayed.take(3).toList();
              final rest = displayed.skip(3).toList();

              return RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () => _ctrl.loadLeaderboard(),
                child: ListView(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.all(AppSizes.md),
                  children: [
                    // ── Podium for Top 3 ───────────────────────────────────
                    if (top3.isNotEmpty) ...[
                      LeaderboardPodium(top3: top3, dark: dark),
                      const SizedBox(height: AppSizes.spaceBtwSections),
                    ],

                    // ── Remaining Rankings (#4+) ───────────────────────────
                    if (rest.isNotEmpty) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'All Rankings',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'Showing ${displayed.length} of ${_ctrl.entries.length}',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: dark
                                  ? Colors.white60
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSizes.sm),
                      ...rest.map(
                        (e) => LeaderboardEntryTile(
                          entry: e,
                          isCurrentUser: e.userId == _ctrl.currentUserId,
                          dark: dark,
                        ),
                      ),
                    ],

                    // ── See More Button (Loads Next 10) ───────────────────
                    if (_ctrl.hasMore) ...[
                      const SizedBox(height: AppSizes.spaceBtwItems),
                      Center(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                          ),
                          onPressed: () => _ctrl.loadMore(),
                          icon: const Icon(Icons.arrow_downward_rounded, size: 16),
                          label: Text('See More (${_ctrl.remainingCount} left)'),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
