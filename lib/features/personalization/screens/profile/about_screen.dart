import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:matricmate/common/widgets/appbar/modern_appbar.dart';
import 'package:matricmate/common/widgets/tiles/list_tile.dart';
import 'package:matricmate/features/personalization/utils/profile_actions_helper.dart';
import 'package:matricmate/utils/constants/app_images.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = AppHelperFunctions.isDark(context);
    final backgroundColor = dark ? AppColors.dark : const Color(0xFFF8FAFC);
    final cardColor = dark ? AppColors.darkCard : AppColors.white;
    final borderColor = dark ? AppColors.darkBorder : const Color(0xFFE2E8F0);
    final textPrimary = dark ? AppColors.white : const Color(0xFF0F172A);
    final textSecondary = dark ? AppColors.darkGrey : AppColors.textSecondary;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: const ModernAppbar(
        title: 'About MatricET',
        showBackArrow: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          MediaQuery.paddingOf(context).bottom + 32,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Hero Brand Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderColor, width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: dark ? 0.25 : 0.04),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // App Icon
                  Container(
                    width: 76,
                    height: 76,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: dark ? 0.18 : 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.25),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Image.asset(
                      AppImages.transparentIcon,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // App Title & Version Pill
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        ProfileActionsHelper.appName,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: const Text(
                          'v${ProfileActionsHelper.appVersion}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Tagline
                  const Text(
                    'Ethiopian University Entrance Examination Prep',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Description
                  Text(
                    'MatricET is an all-in-one exam preparation ecosystem purpose-built for Ethiopian Grade 12 students. We empower students across both Natural and Social Science streams to master the national curriculum, practice authentic past matric papers, and enter exam day with complete confidence.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.55,
                      color: textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 2. Section Header: What MatricET Offers
            Text(
              'WHAT MATRICET OFFERS',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
                color: textSecondary,
              ),
            ),
            const SizedBox(height: 12),

            // Feature Cards
            _FeatureCard(
              icon: Iconsax.timer_1_copy,
              iconColor: const Color(0xFF2563EB),
              title: 'National Entrance Exam Simulator',
              description:
                  'Practice official past matric examinations under real timed conditions. Experience authentic exam pressure, pause and resume sessions anytime, and receive detailed score breakdowns.',
              cardColor: cardColor,
              borderColor: borderColor,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              dark: dark,
            ),
            const SizedBox(height: 10),

            _FeatureCard(
              icon: Iconsax.book_1_copy,
              iconColor: AppColors.primary,
              title: 'Curriculum-Aligned Chapter Tests',
              description:
                  'Reinforce class lessons grade-by-grade and unit-by-unit. Get immediate feedback on every question with detailed, step-by-step explanations for deep conceptual understanding.',
              cardColor: cardColor,
              borderColor: borderColor,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              dark: dark,
            ),
            const SizedBox(height: 10),

            _FeatureCard(
              icon: Iconsax.document_copy,
              iconColor: const Color(0xFF8B5CF6),
              title: 'Curated Notes & Textbooks',
              description:
                  'Access high-yield revision summaries, short notes, and mobile textbook guides across all matric subjects. Read smoothly with an in-app PDF viewer and offline caching.',
              cardColor: cardColor,
              borderColor: borderColor,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              dark: dark,
            ),
            const SizedBox(height: 10),

            _FeatureCard(
              icon: Icons.functions_rounded,
              iconColor: const Color(0xFFD97706),
              title: 'Crystal-Clear Math & Science Rendering',
              description:
                  'Complex mathematical equations, physics formulas, and chemistry notations render natively with full LaTeX support and interactive horizontal touch-scrolling for wide expressions.',
              cardColor: cardColor,
              borderColor: borderColor,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              dark: dark,
            ),
            const SizedBox(height: 10),

            _FeatureCard(
              icon: Icons.local_fire_department_rounded,
              iconColor: const Color(0xFFEF4444),
              title: 'Daily Challenges & Practice Arena',
              description:
                  'Stay consistent with fresh daily question sets. Build study streaks, track your progress on student leaderboards, and sharpen your answering speed under pressure.',
              cardColor: cardColor,
              borderColor: borderColor,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              dark: dark,
            ),
            const SizedBox(height: 10),

            _FeatureCard(
              icon: Icons.bookmark_added_rounded,
              iconColor: const Color(0xFF10B981),
              title: 'Smart Bookmarks & Performance Insights',
              description:
                  'Save tricky questions with a single tap for targeted review before exam day. Monitor your accuracy per subject and focus study time where you need it most.',
              cardColor: cardColor,
              borderColor: borderColor,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              dark: dark,
            ),
            const SizedBox(height: 10),

            _FeatureCard(
              icon: Icons.wifi_off_rounded,
              iconColor: const Color(0xFF64748B),
              title: '100% Offline Capability',
              description:
                  'Study anytime, anywhere without worrying about internet connectivity. Downloaded notes, cached questions, and past practice sessions remain accessible on the go.',
              cardColor: cardColor,
              borderColor: borderColor,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              dark: dark,
            ),
            const SizedBox(height: 24),

            // 3. Educational Streams Supported
            Text(
              'SUPPORTED STREAMS',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
                color: textSecondary,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor, width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: dark ? 0.2 : 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _StreamRow(
                    badge: 'Natural Science',
                    badgeColor: const Color(0xFF2563EB),
                    subjects:
                        'Mathematics, Physics, Chemistry, Biology, English, SAT (Aptitude)',
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Divider(
                      height: 1,
                      thickness: 0.8,
                      color: dark
                          ? Colors.white.withValues(alpha: 0.06)
                          : const Color(0xFFF1F5F9),
                    ),
                  ),
                  _StreamRow(
                    badge: 'Social Science',
                    badgeColor: const Color(0xFF059669),
                    subjects:
                        'Mathematics, Economics, Geography, History, English, SAT (Aptitude)',
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 4. Section Header: Legal & Disclosures
            Text(
              'LEGAL & DISCLOSURES',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
                color: textSecondary,
              ),
            ),
            const SizedBox(height: 10),

            // Legal Card containing Privacy Policy & Open Source Licenses
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: cardColor,
                border: Border.all(color: borderColor, width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: dark ? 0.2 : 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const AppListTile(
                    icon: Icon(
                      Icons.privacy_tip_outlined,
                      color: Color(0xFF0EA5E9),
                      size: 20,
                    ),
                    title: 'Privacy Policy',
                    subtitle: 'Review our data privacy commitment',
                    trailing: const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                    onTap: ProfileActionsHelper.openPrivacyPolicy,
                  ),
                  Divider(
                    height: 1,
                    thickness: 0.8,
                    indent: 58,
                    color: dark
                        ? Colors.white.withValues(alpha: 0.06)
                        : const Color(0xFFF1F5F9),
                  ),
                  AppListTile(
                    icon: const Icon(
                      Iconsax.document_text_1_copy,
                      color: Color(0xFF8B5CF6),
                      size: 18,
                    ),
                    title: 'Open Source Licenses',
                    subtitle: 'Third-party libraries & disclosures',
                    trailing: const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                    onTap: () => showLicensePage(
                      context: context,
                      applicationName: ProfileActionsHelper.appName,
                      applicationVersion: 'v${ProfileActionsHelper.appVersion}',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // 5. Footer & Copyright
            Center(
              child: Column(
                children: [
                  Text(
                    '${ProfileActionsHelper.appName} • Version ${ProfileActionsHelper.appVersion}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Made with ',
                        style: TextStyle(fontSize: 11.5, color: textSecondary),
                      ),
                      const Icon(
                        Icons.favorite_rounded,
                        color: Color(0xFFEF4444),
                        size: 13,
                      ),
                      Text(
                        ' for Ethiopian Grade 12 students',
                        style: TextStyle(fontSize: 11.5, color: textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '© ${DateTime.now().year} Abopia. All rights reserved.',
                    style: TextStyle(
                      fontSize: 11,
                      color: textSecondary.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.cardColor,
    required this.borderColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.dark,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;
  final Color cardColor;
  final Color borderColor;
  final Color textPrimary;
  final Color textSecondary;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: dark ? 0.2 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: dark ? 0.22 : 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: iconColor.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Center(
              child: Icon(
                icon,
                color: iconColor,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.45,
                    color: textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StreamRow extends StatelessWidget {
  const _StreamRow({
    required this.badge,
    required this.badgeColor,
    required this.subjects,
    required this.textPrimary,
    required this.textSecondary,
  });

  final String badge;
  final Color badgeColor;
  final String subjects;
  final Color textPrimary;
  final Color textSecondary;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: badgeColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: badgeColor.withValues(alpha: 0.25),
              width: 1,
            ),
          ),
          child: Text(
            badge,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: badgeColor,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subjects,
          style: TextStyle(
            fontSize: 12.5,
            height: 1.4,
            fontWeight: FontWeight.w500,
            color: textSecondary,
          ),
        ),
      ],
    );
  }
}
