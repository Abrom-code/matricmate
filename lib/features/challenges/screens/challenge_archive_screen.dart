import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart';
import 'package:matricmate/common/widgets/loaders/circular_loading.dart';
import 'package:matricmate/features/challenges/controllers/challenge_archive_controller.dart';
import 'package:matricmate/features/challenges/screens/challenge_attempt_screen.dart';
import 'package:matricmate/features/challenges/screens/challenge_practice_screen.dart';
import 'package:matricmate/features/challenges/screens/leaderboard_screen.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/constants/sizes.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';
import 'package:matricmate/utils/helpers/toast_helper.dart';

class ChallengeArchiveScreen extends StatefulWidget {
  const ChallengeArchiveScreen({super.key, this.subjectId, this.subjectTitle});

  final int? subjectId;
  final String? subjectTitle;

  @override
  State<ChallengeArchiveScreen> createState() => _ChallengeArchiveScreenState();
}

class _ChallengeArchiveScreenState extends State<ChallengeArchiveScreen> {
  late final ChallengeArchiveController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = Get.put(
      ChallengeArchiveController(
        subjectId: widget.subjectId,
        subjectTitle: widget.subjectTitle,
      ),
      tag: widget.subjectId != null ? 'archive_${widget.subjectId}' : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final dark = AppHelperFunctions.isDark(context);

    return Scaffold(
      appBar: AppBar(
        title: Obx(() => Text(_ctrl.selectedSubjectTitle)),
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
              tooltip: 'Refresh',
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () => _ctrl.manualRefresh(),
            );
          }),
          const SizedBox(width: 4),
        ],
      ),
      body: Obx(() {
        if (_ctrl.isLoading.value && _ctrl.challenges.isEmpty) {
          return const AppCircularLoading(
            title: 'Loading challenges...',
          );
        }

        final displayed = _ctrl.displayedChallenges;
        final subjects = _ctrl.studentSubjects;

        return Column(
          children: [
            // ── Horizontal Subject Filter Chips ───────────────────────────
            if (subjects.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: dark ? AppColors.dark : const Color(0xFFF8FAFC),
                  border: Border(
                    bottom: BorderSide(
                      color: dark ? AppColors.darkBorder : AppColors.borderPrimary,
                      width: 1,
                    ),
                  ),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
                  child: Obx(() {
                    final selectedId = _ctrl.selectedSubjectId.value;

                    return Row(
                      children: [
                        // "All" Chip
                        _buildSubjectChip(
                          title: 'All',
                          count: _ctrl.challenges.length,
                          isSelected: selectedId == null,
                          icon: Iconsax.category_copy,
                          dark: dark,
                          onTap: () => _ctrl.selectSubject(null),
                        ),
                        const SizedBox(width: 8),

                        // Individual Subject Chips
                        ...subjects.map((subj) {
                          final isSel = selectedId == subj.id;
                          final count = _ctrl.countForSubject(subj.id);

                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _buildSubjectChip(
                              title: subj.name,
                              count: count,
                              isSelected: isSel,
                              icon: Iconsax.book_copy,
                              dark: dark,
                              onTap: () => _ctrl.selectSubject(subj.id),
                            ),
                          );
                        }),
                      ],
                    );
                  }),
                ),
              ),

            // ── Main Challenges List / Empty State ────────────────────────
            Expanded(
              child: displayed.isEmpty
                  ? RefreshIndicator(
                      color: AppColors.primary,
                      onRefresh: () => _ctrl.manualRefresh(),
                      child: LayoutBuilder(
                        builder: (context, constraints) => SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(minHeight: constraints.maxHeight),
                            child: Center(
                              child: Padding(
                                padding: const EdgeInsets.all(AppSizes.xl),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      width: 72,
                                      height: 72,
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withValues(
                                          alpha: dark ? 0.18 : 0.08,
                                        ),
                                        borderRadius: BorderRadius.circular(22),
                                        border: Border.all(
                                          color: AppColors.primary.withValues(
                                            alpha: dark ? 0.30 : 0.18,
                                          ),
                                          width: 1.5,
                                        ),
                                      ),
                                      child: const Center(
                                        child: Icon(
                                          Iconsax.archive_book_copy,
                                          size: 36,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: AppSizes.md),
                                    Text(
                                      'No ${_ctrl.selectedSubjectTitle} Available',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 16,
                                        letterSpacing: -0.2,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      _ctrl.isOffline.value
                                          ? 'You are offline and have no downloaded challenges for this subject.\nConnect to the internet and tap refresh.'
                                          : 'New rounds and archive challenges will appear here for practice and review.',
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
                            ),
                          ),
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      color: AppColors.primary,
                      onRefresh: () => _ctrl.manualRefresh(),
                      child: ListView.separated(
                        padding: const EdgeInsets.all(AppSizes.md),
                        itemCount: displayed.length + (_ctrl.isOffline.value ? 1 : 0),
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: AppSizes.spaceBtwItems),
                        itemBuilder: (context, idx) {
                          if (_ctrl.isOffline.value && idx == 0) {
                            return Container(
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
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.wifi_off_rounded,
                                    size: 16,
                                    color: Colors.amber,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Offline mode: Showing ${displayed.length} downloaded challenge(s).',
                                      style: const TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.amber,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          final actualIndex = _ctrl.isOffline.value ? idx - 1 : idx;
                          final challenge = displayed[actualIndex];
                          _ctrl.isDownloaded(challenge.id);

              final isLive = challenge.isLive;
              final isScheduled = challenge.isScheduled;

              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
                  side: BorderSide(
                    color: isLive
                        ? AppColors.primary
                        : isScheduled
                            ? const Color(0xFF2563EB)
                            : (dark ? AppColors.darkBorder : AppColors.borderPrimary),
                    width: isLive ? 1.5 : 1.0,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSizes.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header: Subject & Stream & PRO Badge & Delete Button
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(4),
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
                              borderRadius: BorderRadius.circular(4),
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
                            final isPremium = _ctrl.isPremium;
                            if (!isPremium) {
                              return Padding(
                                padding: const EdgeInsets.only(left: AppSizes.xs),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.lock_rounded, size: 10.5, color: Colors.amber),
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
                            final isDone = _ctrl.isAttemptedOrPracticed(
                              challenge.id,
                            );
                            if (isDone) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2.5,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF10B981,
                                  ).withValues(alpha: 0.14),
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
                            final isDown = _ctrl.isDownloaded(challenge.id);
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
                                onPressed: () => _ctrl.confirmDeleteDownload(
                                  context,
                                  challenge,
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          }),
                        ],
                      ),
                      const SizedBox(height: AppSizes.sm),

                      // Title
                      Text(
                        challenge.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14.5,
                        ),
                      ),
                      // Meta Details (Duration, Questions, Date)
                      Wrap(
                        spacing: 12,
                        runSpacing: 4,
                        children: [
                          if (challenge.durationMinutes > 0)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Iconsax.timer_1_copy,
                                  size: 13,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${challenge.durationMinutes} mins',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
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
                                  '${challenge.questionCount} Qs',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: dark ? Colors.white60 : AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          if (challenge.endsAt != null)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Iconsax.calendar_tick_copy,
                                  size: 13,
                                  color: AppColors.textSecondary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  DateFormat('MMM dd, yyyy').format(challenge.endsAt!),
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: dark ? Colors.white60 : AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                      const SizedBox(height: AppSizes.md),

                      // Actions (Leaderboard + Review / Practice / Download / Unlock)
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
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
                            child: Obx(() {
                              final isPremium = _ctrl.isPremium;
                              final isDown = _ctrl.isDownloaded(challenge.id);
                              final isDone = _ctrl.isAttemptedOrPracticed(
                                challenge.id,
                              );
                              final isDownloading =
                                  _ctrl.isDownloading[challenge.id] == true;

                              if (!isPremium) {
                                return FilledButton.icon(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: Colors.amber.shade700,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                    ),
                                  ),
                                  onPressed: () => _ctrl.downloadChallenge(challenge),
                                  icon: const Icon(Icons.lock_rounded, size: 14),
                                  label: const Text(
                                    'Unlock (Pro)',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                );
                              }

                              // 1. If already attempted/completed -> Always show Review!
                              if (isDone) {
                                final isReviewing = _ctrl.isOpeningReview[challenge.id] == true;
                                return FilledButton.icon(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: const Color(0xFF10B981),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                    ),
                                  ),
                                  onPressed: isReviewing
                                      ? null
                                      : () => _ctrl.openCompletedChallenge(challenge),
                                  icon: isReviewing
                                      ? const AppCircularButtonLoading(color: Colors.white)
                                      : const Icon(
                                          Iconsax.document_text_1_copy,
                                          size: 14,
                                        ),
                                  label: Text(
                                    isReviewing ? 'Loading...' : 'Review',
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                );
                              }

                              // 2. Live challenge: show Start button (if not attempted)
                              if (isLive) {
                                if (_ctrl.isOffline.value) {
                                  return FilledButton.icon(
                                    style: FilledButton.styleFrom(
                                      backgroundColor: Colors.grey.shade600,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 8,
                                      ),
                                    ),
                                    onPressed: () => ToastHelper.warning(
                                      'Live challenges require an internet connection.',
                                    ),
                                    icon: const Icon(Icons.wifi_off_rounded, size: 14),
                                    label: const Text(
                                      'Needs Internet',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  );
                                }
                                return FilledButton.icon(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                    ),
                                  ),
                                  onPressed: () => Get.to(
                                    () => ChallengeAttemptScreen(
                                      challengeId: challenge.id,
                                      title: challenge.title,
                                      audience: challenge.audience,
                                    ),
                                  ),
                                  icon: const Icon(Iconsax.play_circle_copy, size: 14),
                                  label: const Text(
                                    'Start Challenge',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                );
                              }

                              // 3. Scheduled challenge: show countdown info
                              if (isScheduled) {
                                return FilledButton.icon(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: const Color(0xFF2563EB),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                    ),
                                  ),
                                  onPressed: null,
                                  icon: const Icon(Iconsax.clock_copy, size: 14),
                                  label: const Text(
                                    'Upcoming',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                );
                              }

                              // 4. Closed challenge: Practice or Download
                              if (isDown) {
                                return FilledButton.icon(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                    ),
                                  ),
                                  onPressed: () => Get.to(
                                    () => ChallengePracticeScreen(
                                      challengeId: challenge.id,
                                      title: challenge.title,
                                    ),
                                  ),
                                  icon: const Icon(
                                    Iconsax.book_1_copy,
                                    size: 14,
                                  ),
                                  label: const Text(
                                    'Practice',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                );
                              }

                              return FilledButton.icon(
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                  ),
                                ),
                                onPressed: isDownloading
                                    ? null
                                    : () => _ctrl.downloadChallenge(challenge),
                                icon: isDownloading
                                    ? const AppCircularButtonLoading(color: Colors.white)
                                    : const Icon(
                                        Iconsax.document_download_copy,
                                        size: 14,
                                      ),
                                label: Text(
                                  isDownloading ? 'Downloading...' : 'Download',
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              );
                            }),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    ],
  );
}),
);
}

  Widget _buildSubjectChip({
    required String title,
    required int count,
    required bool isSelected,
    required IconData icon,
    required bool dark,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary
                : (dark ? AppColors.darkCard : Colors.white),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? AppColors.primary
                  : (dark ? AppColors.darkBorder : AppColors.borderPrimary),
              width: 1.2,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 14,
                color: isSelected
                    ? Colors.white
                    : (dark ? Colors.white70 : AppColors.textSecondary),
              ),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  color: isSelected
                      ? Colors.white
                      : (dark ? Colors.white : const Color(0xFF0F172A)),
                ),
              ),
              if (count > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white.withValues(alpha: 0.25)
                        : (dark ? Colors.white12 : const Color(0xFFF1F5F9)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: isSelected
                          ? Colors.white
                          : (dark ? Colors.white70 : AppColors.textSecondary),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
