import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:matricmate/utils/constants/colors.dart';
import 'package:matricmate/utils/helpers/helper_functions.dart';

class PilotExamComingSoon extends StatefulWidget {
  const PilotExamComingSoon({super.key});

  @override
  State<PilotExamComingSoon> createState() => _PilotExamComingSoonState();
}

class _PilotExamComingSoonState extends State<PilotExamComingSoon> {
  bool _isNotified = false;

  void _toggleNotification() {
    HapticFeedback.mediumImpact();
    setState(() {
      _isNotified = !_isNotified;
    });

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              _isNotified ? Icons.check_circle_rounded : Icons.info_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _isNotified
                    ? "You're on the Pilot Exam waitlist! We'll alert you first."
                    : 'Alert preference removed.',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: _isNotified ? const Color(0xFF0D9488) : AppColors.darkSurface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dark = AppHelperFunctions.isDark(context);

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        MediaQuery.paddingOf(context).bottom + 90,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Hero Banner Card ─────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F766E), Color(0xFF115E59), Color(0xFF042F2C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F766E).withValues(alpha: 0.35),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Tag Row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.bolt_rounded, size: 14, color: Color(0xFFFDE047)),
                          SizedBox(width: 4),
                          Text(
                            'NATIONAL SIMULATION',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFFCD34D), width: 1),
                      ),
                      child: const Text(
                        'COMING SOON',
                        style: TextStyle(
                          color: Color(0xFFFEF08A),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Icon & Title
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.25),
                          width: 1.5,
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Iconsax.timer_1_copy,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pilot Exam Simulator',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              height: 1.2,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'The closest you can get to the real national Matric exam day.',
                            style: TextStyle(
                              color: Color(0xFFCCFBF1),
                              fontSize: 13,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Bottom Call to Action Button in Hero
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton.icon(
                    onPressed: _toggleNotification,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isNotified
                          ? Colors.white.withValues(alpha: 0.2)
                          : Colors.white,
                      foregroundColor: _isNotified ? Colors.white : const Color(0xFF0F766E),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: _isNotified
                            ? const BorderSide(color: Colors.white70, width: 1.2)
                            : BorderSide.none,
                      ),
                    ),
                    icon: Icon(
                      _isNotified ? Icons.check_circle_rounded : Iconsax.notification_bing_copy,
                      size: 18,
                    ),
                    label: Text(
                      _isNotified ? 'Waitlist Joined (Alerts On)' : 'Notify Me When Available',
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 22),

          // ── Features Teaser Header ───────────────────────────────────────
          Text(
            'What you will get in Pilot Exams',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: dark ? Colors.white : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),

          // ── Feature Cards ────────────────────────────────────────────────
          _FeatureHighlightCard(
            dark: dark,
            icon: Iconsax.timer_pause_copy,
            iconColor: const Color(0xFF0D9488),
            title: 'Authentic Exam Conditions',
            description:
                'Full-length timed sessions mimicking the exact duration, questions, and section rules of the Ethiopian National Matric.',
          ),
          const SizedBox(height: 10),
          _FeatureHighlightCard(
            dark: dark,
            icon: Iconsax.ranking_copy,
            iconColor: const Color(0xFF2563EB),
            title: 'National Ranking & Percentile',
            description:
                'Instantly see where your score ranks across thousands of matric candidates throughout the nation.',
          ),
          const SizedBox(height: 10),
          _FeatureHighlightCard(
            dark: dark,
            icon: Iconsax.chart_2_copy,
            iconColor: const Color(0xFF7C3AED),
            title: 'AI Predictive Matric Score',
            description:
                'Calculated probability engine estimating your actual matric score based on past national cutoffs.',
          ),
          const SizedBox(height: 10),
          _FeatureHighlightCard(
            dark: dark,
            icon: Iconsax.document_text_copy,
            iconColor: const Color(0xFFEA580C),
            title: 'Step-by-Step Diagnostic Review',
            description:
                'In-depth rationales for every right and wrong choice, revealing common traps and tricks.',
          ),

          const SizedBox(height: 20),

          // ── Early Access Info Box ────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: dark ? AppColors.darkCard : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: dark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
                width: 1.2,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D9488).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.tips_and_updates_outlined,
                      color: Color(0xFF0D9488),
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pro Tip for Students',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: dark ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Continue practicing individual chapters and reviewing notes to build your baseline strength.',
                        style: TextStyle(
                          fontSize: 12,
                          color: dark ? AppColors.darkGrey : AppColors.textSecondary,
                          height: 1.3,
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
    );
  }
}

class _FeatureHighlightCard extends StatelessWidget {
  const _FeatureHighlightCard({
    required this.dark,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
  });

  final bool dark;
  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: dark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: dark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: dark ? 0.2 : 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Icon(icon, color: iconColor, size: 20),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: dark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: dark ? AppColors.darkGrey : AppColors.textSecondary,
                    height: 1.35,
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
