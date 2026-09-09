import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:matricmate/common/widgets/loaders/circular_loading.dart';
import 'package:matricmate/features/challenges/constants/challenge_colors.dart';
import 'package:matricmate/features/challenges/controllers/challenge_home_controller.dart';
import 'package:matricmate/features/challenges/models/challenge_model.dart';
import 'package:matricmate/features/challenges/screens/leaderboard_screen.dart';
import 'package:matricmate/features/personalization/controllers/user_controller.dart';
import 'package:matricmate/routes/app_routes.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/helpers/ethiopian_time_helper.dart';

/// Modern Challenge Card redesign matching the live/upcoming tournament card mockup.
class AvailableChallengeCard extends StatelessWidget {
  const AvailableChallengeCard({
    super.key,
    required this.challenge,
    required this.ctrl,
    required this.dark,
  });

  final LeaderboardChallengeModel challenge;
  final ChallengeHomeController ctrl;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // Subscribe to real-time timer ticker
      final _ = ctrl.now.value;
      final isPremium = ctrl.isPremium;
      final isLive = challenge.isLive;
      final isDone = ctrl.isAttemptedOrPracticed(challenge.id);
      final inProgress = ctrl.isInProgress(challenge.id);
      final isPending = UserController.instance.user.value.isPending;

      // Countdown calculations
      final targetTime = isLive
          ? (challenge.endsAt ?? challenge.startsAt)
          : challenge.startsAt;

      String hours = '00';
      String minutes = '00';
      String seconds = '00';

      if (targetTime != null) {
        final diff = targetTime.difference(ctrl.now.value);
        final totalSec = diff.isNegative ? 0 : diff.inSeconds;
        hours = (totalSec ~/ 3600).toString().padLeft(2, '0');
        minutes = ((totalSec % 3600) ~/ 60).toString().padLeft(2, '0');
        seconds = (totalSec % 60).toString().padLeft(2, '0');
      }

      // Format Date & Time strings
      final dateSource = isLive
          ? (challenge.endsAt ?? challenge.startsAt)
          : challenge.startsAt;

      final formattedDate = dateSource != null
          ? EthiopianTimeHelper.formatDate(dateSource)
          : 'TBD';

      final formattedTime = dateSource != null
          ? '${EthiopianTimeHelper.formatGregorianTime(dateSource)} (${EthiopianTimeHelper.formatEthiopianTime(dateSource)} ET)'
          : '';

      final subjectColor = _getSubjectColor(challenge.subjectName);
      final subjectIcon = _getSubjectIcon(challenge.subjectName);

      return Container(
        decoration: BoxDecoration(
          color: dark ? AppColors.darkCard : AppColors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: dark
                ? AppColors.darkBorder
                : const Color(0xFFE2E8F0),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: dark ? 0.35 : 0.07),
              blurRadius: 18,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(22),
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: () => ctrl.onChallengeTapped(challenge),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── 1. Header Row (Subject Pill, Audience Badge, Status Badge) ──────
                  Row(
                    children: [
                      // Dynamic Subject Pill
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8.5,
                          vertical: 3.5,
                        ),
                        decoration: BoxDecoration(
                          color: subjectColor.withValues(alpha: dark ? 0.18 : 0.09),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: subjectColor.withValues(alpha: dark ? 0.38 : 0.22),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              subjectIcon,
                              size: 13,
                              color: subjectColor,
                            ),
                            const SizedBox(width: 5),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 125),
                              child: Text(
                                challenge.subjectName ?? 'Challenge',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: dark
                                      ? AppColors.textWhite
                                      : const Color(0xFF0F172A),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 7),

                      // Audience / Stream badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3.5,
                        ),
                        decoration: BoxDecoration(
                          color: dark
                              ? AppColors.darkSurface
                              : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: dark
                                ? AppColors.darkBorder
                                : const Color(0xFFE2E8F0),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          challenge.audience.toUpperCase(),
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                            color: dark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF64748B),
                          ),
                        ),
                      ),

                      const Spacer(),

                      // Status Badge (UPCOMING or LIVE)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4.5,
                        ),
                        decoration: BoxDecoration(
                          color: isLive
                              ? ChallengeColors.live.withValues(alpha: 0.15)
                              : const Color(0xFF0284C7).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isLive
                                ? ChallengeColors.live.withValues(alpha: 0.5)
                                : const Color(0xFF0284C7).withValues(alpha: 0.5),
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isLive ? Icons.circle : Icons.access_time_rounded,
                              size: isLive ? 8 : 12,
                              color: isLive
                                  ? ChallengeColors.live
                                  : const Color(0xFF0284C7),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              isLive ? 'LIVE' : 'UPCOMING',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.6,
                                color: isLive
                                    ? ChallengeColors.live
                                    : const Color(0xFF0284C7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 11),

                  // ── 2. Title with Gradient Accent Bar ─────────────────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 3.5,
                        height: 20,
                        margin: const EdgeInsets.only(top: 2, right: 8.5),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isLive
                                ? [ChallengeColors.live, const Color(0xFFF97316)]
                                : [subjectColor, subjectColor.withValues(alpha: 0.5)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          challenge.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 17.5,
                            fontWeight: FontWeight.w800,
                            height: 1.25,
                            letterSpacing: -0.3,
                            color: dark
                                ? AppColors.textWhite
                                : const Color(0xFF0F172A),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // ── 3. Metrics Row (Duration & Participants) ─────────────
                  Row(
                    children: [
                      // Metric 1: Duration
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: dark
                                ? AppColors.darkSurface
                                : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: dark
                                  ? AppColors.darkBorder
                                  : const Color(0xFFE2E8F0),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: AppColors.primary
                                      .withValues(alpha: dark ? 0.22 : 0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.access_time_rounded,
                                  size: 15,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '${challenge.durationMinutes} mins',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: dark
                                            ? AppColors.textWhite
                                            : const Color(0xFF0F172A),
                                      ),
                                    ),
                                    Text(
                                      'Duration',
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w500,
                                        color: dark
                                            ? const Color(0xFF94A3B8)
                                            : AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Metric 2: Participants
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: dark
                                ? AppColors.darkSurface
                                : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: dark
                                  ? AppColors.darkBorder
                                  : const Color(0xFFE2E8F0),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: AppColors.secondary
                                      .withValues(alpha: dark ? 0.22 : 0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.people_alt_rounded,
                                  size: 15,
                                  color: AppColors.secondary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '${ctrl.getParticipantCount(challenge.id)} joined',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: dark
                                            ? AppColors.textWhite
                                            : const Color(0xFF0F172A),
                                      ),
                                    ),
                                    Text(
                                      'Participants',
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w500,
                                        color: dark
                                            ? const Color(0xFF94A3B8)
                                            : AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // ── 4. Embedded Schedule & Countdown Container ───────────
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: dark
                          ? AppColors.darkSurface
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.primary
                            .withValues(alpha: dark ? 0.25 : 0.14),
                        width: 1.1,
                      ),
                    ),
                    child: Row(
                      children: [
                        // Left: Countdown
                        Expanded(
                          flex: 11,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.calendar_month_outlined,
                                    size: 14,
                                    color: isLive
                                        ? ChallengeColors.live
                                        : AppColors.primary,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    isLive ? 'Ends in' : 'Starts in',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: isLive
                                          ? ChallengeColors.live
                                          : AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 5),
                              Text(
                                '$hours : $minutes : $seconds',
                                style: TextStyle(
                                  fontSize: 18.5,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                  fontFamily: 'monospace',
                                  color: dark
                                      ? AppColors.textWhite
                                      : const Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Hours      Minutes     Seconds',
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w500,
                                  color: dark
                                      ? const Color(0xFF94A3B8)
                                      : AppColors.textSecondary,
                                  letterSpacing: 0.1,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Vertical Divider
                        Container(
                          height: 42,
                          width: 1,
                          color: dark
                              ? AppColors.darkBorder
                              : const Color(0xFFE2E8F0),
                          margin: const EdgeInsets.symmetric(horizontal: 10),
                        ),

                        // Right: Date & Time
                        Expanded(
                          flex: 9,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.calendar_today_rounded,
                                size: 15,
                                color: isLive
                                    ? ChallengeColors.live
                                    : AppColors.primary,
                              ),
                              const SizedBox(width: 7),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      formattedDate,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: dark
                                            ? AppColors.textWhite
                                            : const Color(0xFF0F172A),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      formattedTime,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                        color: dark
                                            ? const Color(0xFF94A3B8)
                                            : AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ── 5. Standings shortcut (if Live) ─────────────────────
                  if (isLive) ...[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.leaderboard_rounded,
                                size: 14,
                                color: Color(0xFFF59E0B),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                'Live Standings',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: dark
                                      ? const Color(0xFFCBD5E1)
                                      : const Color(0xFF475569),
                                ),
                              ),
                            ],
                          ),
                          InkWell(
                            onTap: () => Get.to(
                              () => LeaderboardScreen(
                                challengeId: challenge.id,
                                challengeTitle: challenge.title,
                                audience: challenge.audience,
                              ),
                            ),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 2,
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    'View Rankings',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFFF59E0B),
                                    ),
                                  ),
                                  SizedBox(width: 3),
                                  Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    size: 10,
                                    color: Color(0xFFF59E0B),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // ── 6. Full-Width Glowing Action Button ──────────────────
                  _buildActionButton(
                    context: context,
                    isPremium: isPremium,
                    isPending: isPending,
                    isLive: isLive,
                    isDone: isDone,
                    inProgress: inProgress,
                    dark: dark,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  // ── Action Button Builder ─────────────────────────────────────────────────
  Widget _buildActionButton({
    required BuildContext context,
    required bool isPremium,
    required bool isPending,
    required bool isLive,
    required bool isDone,
    required bool inProgress,
    required bool dark,
  }) {
    // 1. Free / Locked Tier (Unlock to Join)
    if (!isPremium) {
      return _buildPillButton(
        icon: isPending ? Icons.hourglass_top_rounded : Icons.lock_rounded,
        text: isPending
            ? 'Verifying Pro Access'
            : (isLive ? 'Unlock to Join' : 'Unlock to Join (Pro)'),
        gradient: const LinearGradient(
          colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        shadowColor: const Color(0xFFF59E0B),
        textColor: const Color(0xFF1C1917),
        onTap: () {
          if (isPending) {
            Get.toNamed(Routes.paymentVerification);
          } else {
            ctrl.onChallengeTapped(challenge);
          }
        },
      );
    }

    // 2. Active (Premium) & Live Challenge
    if (isLive) {
      if (isDone) {
        final isReviewing = ctrl.isOpeningReview[challenge.id] == true;
        return _buildPillButton(
          icon: Icons.emoji_events_rounded,
          text: 'Review Challenge Results',
          gradient: const LinearGradient(
            colors: [ChallengeColors.completed, Color(0xFF059669)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          shadowColor: ChallengeColors.completed,
          textColor: Colors.white,
          isLoading: isReviewing,
          onTap: isReviewing ? null : () => ctrl.openCompletedChallenge(challenge),
        );
      }

      // Enter Arena / Continue Challenge
      return _buildPillButton(
        icon: inProgress ? Icons.play_arrow_rounded : Icons.rocket_launch_rounded,
        text: inProgress ? 'Continue Challenge' : 'Enter Live Arena',
        gradient: const LinearGradient(
          colors: [AppColors.primary, Color(0xFF0F766E)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        shadowColor: AppColors.primary,
        textColor: Colors.white,
        onTap: () => ctrl.onChallengeTapped(challenge),
      );
    }

    // 3. Active (Premium) & Upcoming Scheduled Challenge
    return _buildPillButton(
      icon: Icons.alarm_on_rounded,
      text: 'Challenge Scheduled',
      gradient: const LinearGradient(
        colors: [ChallengeColors.accent, Color(0xFF0369A1)],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ),
      shadowColor: ChallengeColors.accent,
      textColor: Colors.white,
      onTap: () => ctrl.onChallengeTapped(challenge),
    );
  }

  // ── Unified Glowing Pill Action Button ─────────────────────────────────────
  Widget _buildPillButton({
    required IconData icon,
    required String text,
    required VoidCallback? onTap,
    required Gradient gradient,
    required Color shadowColor,
    required Color textColor,
    bool isLoading = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: onTap,
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: shadowColor.withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: isLoading
              ? Center(child: AppCircularButtonLoading(color: textColor))
              : Row(
                  children: [
                    const SizedBox(width: 18),
                    Icon(icon, size: 19, color: textColor),
                    const SizedBox(width: 12),
                    Container(
                      height: 18,
                      width: 1.2,
                      color: textColor.withValues(alpha: 0.25),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        text,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: textColor,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 19,
                      color: textColor,
                    ),
                    const SizedBox(width: 18),
                  ],
                ),
        ),
      ),
    );
  }

  // ── Subject Icon & Color Helpers ──────────────────────────────────────────
  IconData _getSubjectIcon(String? subjectName) {
    final name = (subjectName ?? '').toLowerCase();
    if (name.contains('math')) return Icons.calculate_rounded;
    if (name.contains('physic')) return Icons.bolt_rounded;
    if (name.contains('chem')) return Icons.science_rounded;
    if (name.contains('bio')) return Icons.biotech_rounded;
    if (name.contains('eng')) return Icons.menu_book_rounded;
    if (name.contains('civic') || name.contains('citizen')) return Icons.balance_rounded;
    if (name.contains('econ')) return Icons.trending_up_rounded;
    if (name.contains('geo')) return Icons.public_rounded;
    if (name.contains('hist')) return Icons.account_balance_rounded;
    if (name.contains('it') || name.contains('info') || name.contains('tech')) return Icons.computer_rounded;
    return Icons.auto_stories_rounded;
  }

  Color _getSubjectColor(String? subjectName) {
    final name = (subjectName ?? '').toLowerCase();
    if (name.contains('math')) return const Color(0xFF0284C7);
    if (name.contains('physic')) return const Color(0xFF8B5CF6);
    if (name.contains('chem')) return const Color(0xFF10B981);
    if (name.contains('bio')) return const Color(0xFF14B8A6);
    if (name.contains('eng')) return const Color(0xFFF59E0B);
    if (name.contains('civic') || name.contains('citizen')) return const Color(0xFFEC4899);
    if (name.contains('econ')) return const Color(0xFF10B981);
    if (name.contains('geo')) return const Color(0xFF06B6D4);
    if (name.contains('hist')) return const Color(0xFFD97706);
    return AppColors.primary;
  }
}
