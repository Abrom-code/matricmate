import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:matricmate/features/challenges/models/challenge_model.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/constants/sizes.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

/// Bottom sheet presenting context-aware actions for managing/deleting challenge data.
class ChallengeManageSheet extends StatelessWidget {
  const ChallengeManageSheet({
    super.key,
    required this.challenge,
    required this.isDownloaded,
    required this.isAttemptedOrPracticed,
    required this.onRemoveDownload,
    required this.onClearPractice,
    required this.onHideChallenge,
  });

  final LeaderboardChallengeModel challenge;
  final bool isDownloaded;
  final bool isAttemptedOrPracticed;
  final VoidCallback onRemoveDownload;
  final VoidCallback onClearPractice;
  final VoidCallback onHideChallenge;

  static Future<void> show({
    required BuildContext context,
    required LeaderboardChallengeModel challenge,
    required bool isDownloaded,
    required bool isAttemptedOrPracticed,
    required VoidCallback onRemoveDownload,
    required VoidCallback onClearPractice,
    required VoidCallback onHideChallenge,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => ChallengeManageSheet(
        challenge: challenge,
        isDownloaded: isDownloaded,
        isAttemptedOrPracticed: isAttemptedOrPracticed,
        onRemoveDownload: onRemoveDownload,
        onClearPractice: onClearPractice,
        onHideChallenge: onHideChallenge,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dark = AppHelperFunctions.isDark(context);
    final sheetBg = dark ? AppColors.darkCard : AppColors.white;

    return Container(
      decoration: BoxDecoration(
        color: sheetBg,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSizes.md,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Drag Handle ─────────────────────────────────────────
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: dark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // ── Header & Challenge Title ────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (challenge.subjectName != null &&
                                challenge.subjectName!.isNotEmpty) ...[
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
                                  challenge.subjectName!,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                            ],
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
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          challenge.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.close_rounded,
                      size: 20,
                      color: dark ? Colors.white60 : AppColors.textSecondary,
                    ),
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            Divider(
              height: 1,
              thickness: 1,
              color: dark ? AppColors.darkBorder : const Color(0xFFF1F5F9),
            ),
            const SizedBox(height: 16),

            // ── Context-Aware Options ───────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
              child: Column(
                children: [
                  // Option 1: Remove Offline Download (only if downloaded)
                  if (isDownloaded) ...[
                    _buildOptionTile(
                      context: context,
                      dark: dark,
                      icon: Icons.cloud_off_rounded,
                      iconColor: const Color(0xFFF59E0B),
                      iconBg: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                      title: 'Remove Offline Download',
                      subtitle:
                          'Free up phone storage by deleting saved questions. You can download again anytime.',
                      onTap: () {
                        Navigator.pop(context);
                        onRemoveDownload();
                      },
                    ),
                    const SizedBox(height: 10),
                  ],

                  // Option 2: Clear Practice Progress (only if practiced/completed)
                  if (isAttemptedOrPracticed) ...[
                    _buildOptionTile(
                      context: context,
                      dark: dark,
                      icon: Icons.restart_alt_rounded,
                      iconColor: AppColors.primary,
                      iconBg: AppColors.primary.withValues(alpha: 0.12),
                      title: 'Clear Practice Progress',
                      subtitle:
                          'Reset your practice answers and score to practice this challenge fresh.',
                      onTap: () {
                        Navigator.pop(context);
                        onClearPractice();
                      },
                    ),
                    const SizedBox(height: 10),
                  ],

                  // Option 3: Hide Challenge from List
                  _buildOptionTile(
                    context: context,
                    dark: dark,
                    icon: Iconsax.trash_copy,
                    iconColor: AppColors.error,
                    iconBg: AppColors.error.withValues(alpha: 0.12),
                    title: 'Hide Challenge',
                    subtitle:
                        'Remove this challenge from your challenges list.',
                    isDestructive: true,
                    onTap: () {
                      Navigator.pop(context);
                      onHideChallenge();
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required BuildContext context,
    required bool dark,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: dark
              ? Colors.white.withValues(alpha: 0.04)
              : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: dark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: isDestructive
                          ? AppColors.error
                          : (dark ? Colors.white : const Color(0xFF0F172A)),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w400,
                      color: dark ? Colors.white60 : AppColors.textSecondary,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 13,
              color: dark ? Colors.white30 : AppColors.grey,
            ),
          ],
        ),
      ),
    );
  }
}
