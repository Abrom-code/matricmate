import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:matricmate/common/widgets/loaders/circular_loading.dart';
import 'package:matricmate/features/challenges/controllers/challenge_archive_controller.dart';
import 'package:matricmate/features/challenges/screens/challenge_practice_screen.dart';
import 'package:matricmate/features/challenges/screens/leaderboard_screen.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/constants/sizes.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

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
    final screenTitle = widget.subjectTitle != null
        ? '${widget.subjectTitle} Challenges'
        : 'Past Challenges Archive';

    return Scaffold(
      appBar: AppBar(
        title: Text(screenTitle),
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
          return AppCircularLoading(
            title: widget.subjectTitle != null
                ? 'Loading ${widget.subjectTitle} challenges...'
                : 'Loading archived challenges...',
          );
        }

        if (_ctrl.challenges.isEmpty) {
          return RefreshIndicator(
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
                          Icon(
                            Iconsax.archive_book_copy,
                            size: 48,
                            color: dark
                                ? Colors.white24
                                : AppColors.textSecondary,
                          ),
                          const SizedBox(height: AppSizes.md),
                          Text(
                            widget.subjectTitle != null
                                ? 'No past ${widget.subjectTitle} challenges yet'
                                : 'No past challenges available yet',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Once live rounds close, they will appear here for practice and review.',
                            textAlign: TextAlign.center,
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
            ),
          );
        }

        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () => _ctrl.manualRefresh(),
          child: ListView.separated(
            padding: const EdgeInsets.all(AppSizes.md),
            itemCount: _ctrl.challenges.length,
            separatorBuilder: (_, __) =>
                const SizedBox(height: AppSizes.spaceBtwItems),
            itemBuilder: (context, idx) {
              final challenge = _ctrl.challenges[idx];
              _ctrl.isDownloaded(challenge.id);

              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.borderRadiusMd),
                  side: BorderSide(
                    color: dark
                        ? AppColors.darkBorder
                        : AppColors.borderPrimary,
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
                            final isDown = _ctrl.isDownloaded(challenge.id);
                            final isDone = _ctrl.isAttemptedOrPracticed(
                              challenge.id,
                            );
                            if (isDown && isDone) {
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
                      const SizedBox(height: 4),
                      const Text(
                        'Practice offline at your own pace with answers & explanations.',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSizes.md),

                      // Actions (Leaderboard + Review / Practice / Download / Unlock)
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(0, 38),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                  horizontal: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
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
                                'Leaderboard',
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
                                    minimumSize: const Size(0, 38),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                      horizontal: 10,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
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

                              if (isDown && isDone) {
                                return FilledButton.icon(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: const Color(0xFF10B981),
                                    minimumSize: const Size(0, 38),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                      horizontal: 10,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  onPressed: () =>
                                      _ctrl.openCompletedChallenge(challenge),
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
                                );
                              }

                              if (isDown) {
                                return FilledButton.icon(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    minimumSize: const Size(0, 38),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                      horizontal: 10,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
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
                                  minimumSize: const Size(0, 38),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                    horizontal: 10,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                onPressed: isDownloading
                                    ? null
                                    : () => _ctrl.downloadChallenge(challenge),
                                icon: isDownloading
                                    ? const SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
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
        );
      }),
    );
  }
}
