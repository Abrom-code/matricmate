import 'package:matricmate/features/challenges/screens/challenge_archive_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart';
import 'package:matricmate/common/widgets/appbar/modern_appbar.dart';
import 'package:matricmate/common/widgets/loaders/circular_loading.dart';
import 'package:matricmate/features/challenges/controllers/challenge_home_controller.dart';
import 'package:matricmate/features/challenges/models/challenge_model.dart';
import 'package:matricmate/features/exam/models/subject_model.dart';
import 'package:matricmate/features/challenges/screens/leaderboard_screen.dart';
import 'package:matricmate/features/challenges/screens/challenge_practice_screen.dart';
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
        title: '🏆 Challenges',
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
            icon: const Icon(Icons.leaderboard_rounded, color: Colors.white),
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
                unselectedLabelColor: dark
                    ? Colors.white60
                    : AppColors.textSecondary,
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
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Flexible(
                          child: Text(
                            'Available',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (_ctrl.availableChallenges.isNotEmpty) ...[
                          const SizedBox(width: 5),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${_ctrl.availableChallenges.length}',
                              style: const TextStyle(
                                fontSize: 10.5,
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
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Flexible(
                          child: Text(
                            'Completed / Past',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (_ctrl.completedChallenges.isNotEmpty) ...[
                          const SizedBox(width: 5),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: dark
                                  ? Colors.white12
                                  : const Color(0xFFE2E8F0),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${_ctrl.completedChallenges.length}',
                              style: TextStyle(
                                fontSize: 10.5,
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
                        ? SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            child: SizedBox(
                              height: MediaQuery.of(context).size.height * 0.68,
                              child: _OfflineAvailableState(
                                ctrl: _ctrl,
                                dark: dark,
                              ),
                            ),
                          )
                        : _ctrl.availableChallenges.isEmpty
                            ? _EmptyState(
                                title: 'No available rounds currently',
                                subtitle:
                                    'Upcoming challenges will appear here before they open.',
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
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: AppSizes.spaceBtwItems),
                                itemBuilder: (context, index) {
                                  final challenge =
                                      _ctrl.availableChallenges[index];
                                  return _AvailableChallengeCard(
                                    challenge: challenge,
                                    ctrl: _ctrl,
                                    dark: dark,
                                  );
                                },
                              ),
                  ),

                  // Tab 2: Completed / Past Challenges (Top Recent 3 + Subject TabBar)
                  RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: () => _ctrl.loadAllChallenges(isManual: true),
                    child: _ctrl.completedChallenges.isEmpty
                        ? (_ctrl.isOffline.value
                            ? SingleChildScrollView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                child: SizedBox(
                                  height: MediaQuery.of(context).size.height * 0.68,
                                  child: _EmptyState(
                                    title: 'No offline challenges downloaded',
                                    subtitle:
                                        'You are offline. Challenge sets downloaded while online will appear here for offline practice.',
                                    dark: dark,
                                    icon: Icons.wifi_off_rounded,
                                  ),
                                ),
                              )
                            : _EmptyState(
                                title: 'No completed challenges yet',
                                subtitle:
                                    'Once live challenges end, you can review and practice them here.',
                                dark: dark,
                              ))
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
                                  margin: const EdgeInsets.only(bottom: AppSizes.md),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8.5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: Colors.amber.withValues(alpha: 0.3),
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
                                    child: _CompletedChallengeCard(
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
                                    color: Color(0xFF0284C7),
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
                                child: _SubjectNavCard(
                                  customTitle: 'All Subjects',
                                  customIcon: Iconsax.category_copy,
                                  customAccentColor: const Color(0xFF0284C7),
                                  challengeCount: _ctrl.availableChallenges.length +
                                      _ctrl.completedChallenges.length,
                                  dark: dark,
                                  isOffline: _ctrl.isOffline.value,
                                  onTap: () => Get.to(
                                    () => const ChallengeArchiveScreen(
                                      subjectId: null,
                                      subjectTitle: 'All Subjects',
                                    ),
                                  ),
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
                                  child: _SubjectNavCard(
                                    subject: subj,
                                    challengeCount: count,
                                    dark: dark,
                                    isOffline: _ctrl.isOffline.value,
                                    onTap: () => Get.to(
                                      () => ChallengeArchiveScreen(
                                        subjectId: subj.id,
                                        subjectTitle: subj.name,
                                      ),
                                    ),
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
                        color: const Color(0xFF10B981).withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            size: 12,
                            color: Color(0xFF10B981),
                          ),
                          SizedBox(width: 3.5),
                          Text(
                            'Completed',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF10B981),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
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
                              : const Color(0xFF2563EB),
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
                                  return FilledButton.icon(
                                    style: FilledButton.styleFrom(
                                      backgroundColor: const Color(0xFF10B981),
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                    ),
                                    onPressed: isReviewing
                                        ? null
                                        : () => ctrl.openCompletedChallenge(challenge),
                                    icon: isReviewing
                                        ? const AppCircularButtonLoading(color: Colors.white)
                                        : const Icon(
                                            Iconsax.document_text_1_copy,
                                            size: 16,
                                          ),
                                    label: Text(
                                      isReviewing ? 'Loading...' : 'Review Attempt',
                                      style: const TextStyle(
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
                      color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Iconsax.clock_copy,
                          size: 14,
                          color: Color(0xFF2563EB),
                        ),
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
  });
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
                  final isPremium = ctrl.isPremium;
                  if (!isPremium) {
                    return Padding(
                      padding: const EdgeInsets.only(left: AppSizes.xs),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2.5,
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
                    );
                  }
                  return const SizedBox.shrink();
                }),
                const SizedBox(width: AppSizes.xs),
                Obx(() {
                  final isDown = ctrl.isDownloaded(challenge.id);
                  final isDone = ctrl.isAttemptedOrPracticed(challenge.id);
                  if (isDown && isDone) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2.5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle_rounded,
                            size: 12,
                            color: Color(0xFF10B981),
                          ),
                          SizedBox(width: 3.5),
                          Text(
                            'Done',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF10B981),
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
                  if (isDown) {
                    return IconButton(
                      tooltip: 'Remove offline download',
                      icon: const Icon(
                        Iconsax.trash_copy,
                        size: 16,
                        color: AppColors.error,
                      ),
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () =>
                          ctrl.confirmDeleteDownload(context, challenge),
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
                const Icon(
                  Iconsax.calendar_tick_copy,
                  size: 13,
                  color: AppColors.textSecondary,
                ),
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
                    style: TextStyle(
                      fontSize: 11.5,
                      color: dark ? Colors.white60 : AppColors.textSecondary,
                    ),
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
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        onPressed: () => ctrl.downloadChallenge(challenge),
                        icon: const Icon(Icons.lock_rounded, size: 14),
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
                                backgroundColor: const Color(0xFF10B981),
                                padding: const EdgeInsets.symmetric(vertical: 8),
                              ),
                              onPressed: null,
                              child: const AppCircularButtonLoading(color: Colors.white),
                            )
                          : FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF10B981),
                                padding: const EdgeInsets.symmetric(vertical: 8),
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
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 8),
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
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                            onPressed: null,
                            child: const AppCircularButtonLoading(color: Colors.white),
                          )
                        : FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(vertical: 8),
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
    this.icon,
  });

  final String title;
  final String subtitle;
  final bool dark;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: dark ? 0.18 : 0.08),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: dark ? 0.30 : 0.18),
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Icon(
                  icon ?? Iconsax.cup_copy,
                  size: 36,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: AppSizes.md),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                height: 1.45,
                color: dark ? AppColors.darkGrey : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Offline Available State ──────────────────────────────────────────────────

class _OfflineAvailableState extends StatelessWidget {
  const _OfflineAvailableState({
    required this.ctrl,
    required this.dark,
  });

  final ChallengeHomeController ctrl;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: dark ? 0.18 : 0.10),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.amber.withValues(alpha: dark ? 0.40 : 0.25),
                  width: 1.5,
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.wifi_off_rounded,
                  size: 36,
                  color: Colors.amber,
                ),
              ),
            ),
            const SizedBox(height: AppSizes.md),
            const Text(
              'Connect to Internet & Refresh',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16.5,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Active and upcoming live challenges require an internet connection.\nPlease connect to the internet and tap refresh.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                height: 1.45,
                color: dark ? AppColors.darkGrey : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSizes.lg),
            Obx(() {
              final isBusy = ctrl.isRefreshing.value || ctrl.isLoading.value;
              return SizedBox(
                height: 44,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    side: const BorderSide(
                      color: AppColors.primary,
                      width: 1.5,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: isBusy ? null : () => ctrl.loadAllChallenges(isManual: true),
                  icon: isBusy
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.refresh_rounded, size: 18),
                  label: Text(
                    isBusy ? 'Refreshing...' : 'Connect & Refresh',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13.5,
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

// ── Subject Navigation Card ──────────────────────────────────────────────────

class _SubjectNavCard extends StatelessWidget {
  const _SubjectNavCard({
    this.subject,
    this.customTitle,
    this.customIcon,
    this.customAccentColor,
    required this.challengeCount,
    required this.dark,
    required this.onTap,
    this.isOffline = false,
  });

  final SubjectModel? subject;
  final String? customTitle;
  final IconData? customIcon;
  final Color? customAccentColor;
  final int challengeCount;
  final bool dark;
  final VoidCallback onTap;
  final bool isOffline;

  @override
  Widget build(BuildContext context) {
    final title = customTitle ?? subject?.name ?? 'Subject';
    final icon = customIcon ?? Iconsax.book_copy;
    final accent = customAccentColor ?? AppColors.primary;

    String subtitleText;
    if (isOffline) {
      subtitleText = challengeCount > 0
          ? '$challengeCount ${challengeCount == 1 ? 'challenge' : 'challenges'} loaded'
          : '0 challenges loaded';
    } else {
      subtitleText = challengeCount > 0
          ? '$challengeCount challenge rounds'
          : '0 rounds';
    }

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
        side: BorderSide(
          color: dark ? AppColors.darkBorder : AppColors.borderPrimary,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: dark ? 0.22 : 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 19,
                  color: accent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitleText,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: dark ? Colors.white60 : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: isOffline
                      ? (dark
                          ? (challengeCount > 0
                              ? const Color(0xFF10B981).withValues(alpha: 0.15)
                              : Colors.white10)
                          : (challengeCount > 0
                              ? const Color(0xFFD1FAE5)
                              : const Color(0xFFF1F5F9)))
                      : (dark ? Colors.white10 : const Color(0xFFF1F5F9)),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$challengeCount',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isOffline && challengeCount > 0
                        ? const Color(0xFF10B981)
                        : (dark ? Colors.white70 : AppColors.textSecondary),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: dark ? Colors.white38 : AppColors.textSecondary.withValues(alpha: 0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
