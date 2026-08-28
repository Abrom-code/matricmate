import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:matricmate/features/exam/models/subject_model.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/constants/sizes.dart';

class ChallengeSubjectNavCard extends StatelessWidget {
  const ChallengeSubjectNavCard({
    super.key,
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
