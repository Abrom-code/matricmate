import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:matricmate/common/widgets/appbar/modern_appbar.dart';
import 'package:matricmate/common/widgets/loaders/circular_loading.dart';
import 'package:matricmate/features/challenges/constants/challenge_colors.dart';
import 'package:matricmate/features/challenges/controllers/challenge_home_controller.dart';
import 'package:matricmate/features/challenges/screens/challenge_archive_screen.dart';
import 'package:matricmate/features/challenges/screens/leaderboard_screen.dart';
import 'package:matricmate/features/challenges/screens/widgets/available_challenge_card.dart';
import 'package:matricmate/features/challenges/screens/widgets/challenge_empty_states.dart';
import 'package:matricmate/features/challenges/screens/widgets/challenge_subject_nav_card.dart';
import 'package:matricmate/features/challenges/screens/widgets/completed_challenge_card.dart';
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
  Worker? _tabWorker;

  @override
  void initState() {
    super.initState();
    _ctrl = Get.put(ChallengeHomeController());
    _tabCtrl = TabController(
      length: 2,
      vsync: this,
      initialIndex: _ctrl.selectedTabIndex.value.clamp(0, 1),
    );
    _tabCtrl.addListener(() {
      if (!_tabCtrl.indexIsChanging) {
        _ctrl.selectedTabIndex.value = _tabCtrl.index;
      }
    });
    _tabWorker = ever(_ctrl.selectedTabIndex, (idx) {
      if (_tabCtrl.index != idx && idx >= 0 && idx < _tabCtrl.length) {
        _tabCtrl.animateTo(idx);
      }
    });
  }

  @override
  void dispose() {
    _tabWorker?.dispose();
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = AppHelperFunctions.isDark(context);

    return Scaffold(
      appBar: ModernAppbarWithBuilder(
        title: 'Challenges',
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
            icon: const Icon(Icons.leaderboard_rounded, color: Colors.teal),
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
                isScrollable: false,
                labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                labelColor: AppColors.primary,
                unselectedLabelColor:
                    dark ? Colors.white60 : AppColors.textSecondary,
                indicatorColor: AppColors.primary,
                indicatorWeight: 3,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12.5,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 12.5,
                ),
                tabs: [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Available'),
                        if (_ctrl.hasLiveChallenges) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1.5,
                            ),
                            decoration: BoxDecoration(
                              color: ChallengeColors.live,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'LIVE',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ] else if (_ctrl.availableChallenges.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1.5,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${_ctrl.availableChallenges.length}',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
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
                        const Text('Completed / Archive'),
                        if (_ctrl.completedChallenges.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1.5,
                            ),
                            decoration: BoxDecoration(
                              color: dark
                                  ? AppColors.darkContainer
                                  : const Color(0xFFE2E8F0),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${_ctrl.completedChallenges.length}',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: dark
                                    ? Colors.white70
                                    : AppColors.textSecondary,
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
                  _ctrl.completedChallenges.isEmpty &&
                  !_ctrl.isOffline.value) {
                return const AppCircularLoading(title: 'Loading challenges...');
              }

              return TabBarView(
                controller: _tabCtrl,
                children: [
                  // Tab 1: Available Challenges
                  RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: () => _ctrl.loadAllChallenges(isManual: true),
                    child: _ctrl.isOffline.value && _ctrl.availableChallenges.isEmpty
                        ? LayoutBuilder(
                            builder: (context, constraints) => SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  minHeight: constraints.maxHeight,
                                ),
                                child: Center(
                                  child: ChallengeOfflineState(
                                    dark: dark,
                                    isRefreshing: _ctrl.isRefreshing.value ||
                                        _ctrl.isLoading.value,
                                    onRefresh: () =>
                                        _ctrl.loadAllChallenges(isManual: true),
                                  ),
                                ),
                              ),
                            ),
                          )
                        : _ctrl.availableChallenges.isEmpty
                            ? LayoutBuilder(
                                builder: (context, constraints) =>
                                    SingleChildScrollView(
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(
                                      minHeight: constraints.maxHeight,
                                    ),
                                    child: Center(
                                      child: ChallengeEmptyState(
                                        title: 'No available rounds currently',
                                        subtitle:
                                            'Upcoming challenges will appear here before they open.',
                                        dark: dark,
                                      ),
                                    ),
                                  ),
                                ),
                              )
                            : ListView.separated(
                                padding: EdgeInsets.fromLTRB(
                                  AppSizes.md,
                                  AppSizes.md,
                                  AppSizes.md,
                                  MediaQuery.paddingOf(context).bottom + 90,
                                ),
                                itemCount: _ctrl.availableChallenges.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: AppSizes.spaceBtwItems),
                                itemBuilder: (context, index) {
                                  final challenge =
                                      _ctrl.availableChallenges[index];
                                  return AvailableChallengeCard(
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
                    onRefresh: () => _ctrl.loadAllChallenges(isManual: true),
                    child: _ctrl.completedChallenges.isEmpty
                        ? LayoutBuilder(
                            builder: (context, constraints) =>
                                SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  minHeight: constraints.maxHeight,
                                ),
                                child: Center(
                                  child: _ctrl.isOffline.value
                                      ? ChallengeEmptyState(
                                          title:
                                              'No offline challenges downloaded',
                                          subtitle:
                                              'You are offline. Challenge sets downloaded while online will appear here for offline practice.',
                                          dark: dark,
                                          icon: Icons.wifi_off_rounded,
                                        )
                                      : ChallengeEmptyState(
                                          title: 'No completed challenges yet',
                                          subtitle:
                                              'Once live challenges end, you can review and practice them here.',
                                          dark: dark,
                                        ),
                                ),
                              ),
                            ),
                          )
                        : ListView(
                            padding: EdgeInsets.fromLTRB(
                              AppSizes.md,
                              AppSizes.md,
                              AppSizes.md,
                              MediaQuery.paddingOf(context).bottom + 90,
                            ),
                            children: [
                              if (_ctrl.isOffline.value) ...[
                                Container(
                                  margin:
                                      const EdgeInsets.only(bottom: AppSizes.md),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8.5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color:
                                          Colors.amber.withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(
                                        Icons.wifi_off_rounded,
                                        size: 16,
                                        color: Colors.amber,
                                      ),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Offline mode: Showing your downloaded challenges.',
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.amber,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],

                              // ── 1. Top Section: Recent 3 Completed Rounds ──
                              if (_ctrl.recentCompletedChallenges.isNotEmpty) ...[
                                Row(
                                  children: [
                                    const Icon(
                                      Iconsax.clock_copy,
                                      size: 15,
                                      color: AppColors.primary,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      _ctrl.isOffline.value
                                          ? 'Downloaded Challenges'
                                          : 'Recent Challenges',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const Spacer(),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 7,
                                        vertical: 2.5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withValues(
                                          alpha: 0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        'Latest ${_ctrl.recentCompletedChallenges.length}',
                                        style: const TextStyle(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),

                                // Recent 3 Cards
                                ..._ctrl.recentCompletedChallenges.map((
                                  challenge,
                                ) {
                                  return Padding(
                                    padding: const EdgeInsets.only(
                                      bottom: AppSizes.spaceBtwItems,
                                    ),
                                    child: CompletedChallengeCard(
                                      challenge: challenge,
                                      ctrl: _ctrl,
                                      dark: dark,
                                    ),
                                  );
                                }),

                                const SizedBox(height: AppSizes.sm),
                                Divider(
                                  color: dark
                                      ? AppColors.darkBorder
                                      : AppColors.borderPrimary,
                                ),
                                const SizedBox(height: AppSizes.md),
                              ],

                              // ── 2. Next Section: Subjects List ───────
                              Row(
                                children: [
                                  const Icon(
                                    Iconsax.book_1_copy,
                                    size: 15,
                                    color: ChallengeColors.accent,
                                  ),
                                  const SizedBox(width: 6),
                                  const Text(
                                    'Browse by Subject',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    'All + ${_ctrl.studentSubjects.length} subjects',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: dark
                                          ? Colors.white60
                                          : AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),

                              // "All Subjects" Navigation Card
                              Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: ChallengeSubjectNavCard(
                                  customTitle: 'All Subjects',
                                  customIcon: Iconsax.category_copy,
                                  customAccentColor: ChallengeColors.accent,
                                  challengeCount:
                                      _ctrl.availableChallenges.length +
                                          _ctrl.completedChallenges.length,
                                  dark: dark,
                                  isOffline: _ctrl.isOffline.value,
                                  onTap: () async {
                                    await Get.to(
                                      () => const ChallengeArchiveScreen(
                                        subjectId: null,
                                        subjectTitle: 'All Subjects',
                                      ),
                                    );
                                    _ctrl.refreshDownloadStates();
                                    _ctrl.refreshAttemptStates();
                                  },
                                ),
                              ),

                              // Subject Navigation Cards
                              ..._ctrl.studentSubjects.map((subj) {
                                final count = _ctrl.availableChallenges
                                        .where((c) => c.subjectId == subj.id)
                                        .length +
                                    _ctrl.completedChallenges
                                        .where((c) => c.subjectId == subj.id)
                                        .length;

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: ChallengeSubjectNavCard(
                                    subject: subj,
                                    challengeCount: count,
                                    dark: dark,
                                    isOffline: _ctrl.isOffline.value,
                                    onTap: () async {
                                      await Get.to(
                                        () => ChallengeArchiveScreen(
                                          subjectId: subj.id,
                                          subjectTitle: subj.name,
                                        ),
                                      );
                                      _ctrl.refreshDownloadStates();
                                      _ctrl.refreshAttemptStates();
                                    },
                                  ),
                                );
                              }),
                            ],
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
