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
  const ChallengeArchiveScreen({super.key});

  @override
  State<ChallengeArchiveScreen> createState() => _ChallengeArchiveScreenState();
}

class _ChallengeArchiveScreenState extends State<ChallengeArchiveScreen> {
  late final ChallengeArchiveController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = Get.put(ChallengeArchiveController());
  }

  @override
  Widget build(BuildContext context) {
    final dark = AppHelperFunctions.isDark(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Past Challenges Archive'),
        actions: [
          IconButton(
            tooltip: 'Refresh Archive',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => _ctrl.loadArchive(),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Obx(() {
        if (_ctrl.isLoading.value && _ctrl.challenges.isEmpty) {
          return const AppCircularLoading(title: 'Loading archived challenges...');
        }

        if (_ctrl.challenges.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Iconsax.archive_book_copy, size: 48, color: dark ? Colors.white24 : AppColors.textSecondary),
                const SizedBox(height: AppSizes.md),
                const Text(
                  'No past challenges available yet',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Once live rounds close, they will be archived here for offline review.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () => _ctrl.loadArchive(),
          child: ListView.separated(
            padding: const EdgeInsets.all(AppSizes.md),
            itemCount: _ctrl.challenges.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSizes.spaceBtwItems),
            itemBuilder: (context, idx) {
              final challenge = _ctrl.challenges[idx];
              final isDown = _ctrl.isDownloaded(challenge.id);
              final isDownloading = _ctrl.isDownloading[challenge.id] == true;

              return Card(
                elevation: 0,
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
                      // Header: Subject & Stream
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
                          if (isDown)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.success.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.check_circle_rounded, size: 12, color: AppColors.success),
                                  SizedBox(width: 3),
                                  Text(
                                    'Downloaded',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.success,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: AppSizes.sm),

                      // Title
                      Text(
                        challenge.title,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Practice offline at your own pace with answers & explanations.',
                        style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: AppSizes.md),

                      // Actions
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                              ),
                              onPressed: () => Get.to(
                                () => LeaderboardScreen(
                                  challengeId: challenge.id,
                                  challengeTitle: challenge.title,
                                  audience: challenge.audience,
                                ),
                              ),
                              icon: const Icon(Iconsax.ranking_copy, size: 14),
                              label: const Text('Leaderboard', style: TextStyle(fontSize: 11.5)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 2,
                            child: isDown
                                ? FilledButton.icon(
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
                                    label: const Text('Practice', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                                  )
                                : FilledButton.icon(
                                    style: FilledButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                    ),
                                    onPressed: isDownloading
                                        ? null
                                        : () => _ctrl.downloadChallenge(challenge),
                                    icon: isDownloading
                                        ? const SizedBox(
                                            width: 14,
                                            height: 14,
                                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                          )
                                        : const Icon(Iconsax.document_download_copy, size: 14),
                                    label: Text(
                                      isDownloading ? 'Downloading...' : 'Download',
                                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                                    ),
                                  ),
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
